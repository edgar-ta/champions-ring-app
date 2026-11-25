import type {DocumentReference} from "firebase-admin/firestore";
import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {CoreDate} from "../core/models/core_date.js";
import {
  CoreClientRepository,
} from "../core/repositories/core_client_repository.js";
import {
  CorePaymentRepository,
} from "../core/repositories/core_payment_repository.js";
import {
  db,
  MP_ACCESS_TOKEN_V2,
  REGION,
  REUSE_WINDOW_MS,
} from "../core/utils/constants.js";
import {MercadoPagoPayment} from "../shared/models/payment.js";
import type {RegisterOrderItem} from "../shared/models/register_order.js";
import {registerOrder} from "../shared/utils/register_order.js";

/**
 * Registra un documento de tipo `mercado-pago` en la colección `payments`.
 *
 * El cuerpo de la solicitud requiere los siguientes parámetros:
 * - `paymentUid: string`. La id única a la cual estará asociada el
 *   pago a crear.
 * - `simpleItems: RegisterOrderItem[]`. La lista de ítems para los cuales
 *   se está generando un pago. Se utiliza para mostrarle el resumen
 *   de pago al cliente en la página de Mercado Pago.
 * - `clientUid: string?`. La id del cliente que realiza el pago.
 *
 * Esta función calcula el total a cobrar al usuario a partir de
 * `simpleItems`; no se verifica la veracidad de los elementos de este arreglo.
 *
 * En caso de no ser nulo, el atributo `clientUid` debe hacer referencia
 * a un cliente válido.
 *
 * Si ya existe un pago con la UID indicada, se reutiliza su URL cuando
 * corresponde al mismo monto y cliente y se creó dentro de `REUSE_WINDOW_MS`.
 *
 * De ser exitosa, la respuesta de la función tiene la siguiente forma:
 * `{ checkoutUrl: string }`.
 */
export const createPaymentCheckout = onCall(
  {region: REGION, secrets: [MP_ACCESS_TOKEN_V2]},
  async (request) => {
    const paymentUid: unknown = request.data?.paymentUid;
    if (
      typeof paymentUid !== "string" ||
      paymentUid.trim() === "" ||
      paymentUid.includes("/")
    ) {
      throw new HttpsError(
        "invalid-argument",
        "El identificador del pago no es válido.",
      );
    }

    const items = parseSimpleItems(request.data?.simpleItems);
    const clientUid: unknown = request.data?.clientUid;
    if (
      clientUid !== undefined &&
      clientUid !== null &&
      (typeof clientUid !== "string" ||
        clientUid.trim() === "" ||
        clientUid.includes("/"))
    ) {
      throw new HttpsError(
        "invalid-argument",
        "El identificador del cliente no es válido.",
      );
    }

    let payerRef: DocumentReference | undefined;
    let payer: {
      email: string;
      firstName: string;
      lastName: string;
    } | undefined;
    if (typeof clientUid === "string") {
      const clientRepository = new CoreClientRepository(db);
      const client = await clientRepository.findById(clientUid);
      if (client === undefined) {
        throw new HttpsError(
          "invalid-argument",
          "El cliente especificado no existe.",
        );
      }
      payerRef = clientRepository.collection.doc(clientUid);
      payer = {
        email: client.email,
        firstName: client.name,
        lastName: client.lastName,
      };
    }

    const amountCents = items.reduce(
      (total, item) =>
        total + item.quantity * Math.round(item.unitPrice * 100),
      0,
    );
    const amount = amountCents / 100;

    if (!Number.isSafeInteger(amountCents) || amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "El monto del pago debe ser mayor que cero.",
      );
    }

    const paymentRepository = new CorePaymentRepository(db);
    const existingPayment = await paymentRepository.findById(paymentUid);
    if (existingPayment !== undefined) {
      if (
        existingPayment.type !== "mercado-pago" ||
        existingPayment.amount !== amount ||
        existingPayment.payerRef?.path !== payerRef?.path
      ) {
        throw new HttpsError(
          "already-exists",
          "La UID ya está asociada a otro pago.",
        );
      }

      if (
        existingPayment.status === "processing" &&
        existingPayment.checkoutUrl
      ) {
        const creationDate =
          existingPayment.creationDate.timestamp?.toMillis() ??
          existingPayment.creationDate.dateTime?.getTime();
        if (
          creationDate !== undefined &&
          Math.abs(Date.now() - creationDate) <= REUSE_WINDOW_MS
        ) {
          return {checkoutUrl: existingPayment.checkoutUrl};
        }

        throw new HttpsError(
          "already-exists",
          "La UID ya está asociada a un checkout anterior; genera otra UID.",
        );
      }

      if (
        existingPayment.status !== undefined &&
        existingPayment.status !== "processing"
      ) {
        throw new HttpsError(
          "already-exists",
          "La UID ya está asociada a un pago que no se puede reemplazar.",
        );
      }
    }

    const payment = new MercadoPagoPayment({
      uid: paymentUid,
      amount,
      currency: "MXN",
      creationDate: CoreDate.ofWriteTime(),
      payerRef,
      status: "processing",
    });

    await paymentRepository.upsert(payment.toCorePayment());

    let order: {id: string; checkoutUrl: string};

    try {
      order = await registerOrder({
        paymentUid,
        items,
        payer,
      });
    } catch (error) {
      logger.error("No se pudo contactar a Mercado Pago", error);
      await paymentRepository.collection.doc(paymentUid).update({
        status: FieldValue.delete(),
      });
      throw new HttpsError(
        "unavailable",
        "No fue posible conectar con Mercado Pago. Intenta de nuevo.",
      );
    }

    await paymentRepository.collection.doc(paymentUid).update({
      checkoutUrl: order.checkoutUrl,
    });

    return {checkoutUrl: order.checkoutUrl};
  },
);

/**
 * Valida los campos del artículo sin consultar un catálogo confiable.
 * @param {unknown} value Valor recibido en la solicitud.
 * @return {RegisterOrderItem[]} Artículos validados para el checkout.
 */
function parseSimpleItems(value: unknown): RegisterOrderItem[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Debes incluir al menos un artículo para el pago.",
    );
  }

  return value.map((item): RegisterOrderItem => {
    if (
      typeof item !== "object" ||
      item === null ||
      Array.isArray(item)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "La lista de artículos contiene un elemento no válido.",
      );
    }

    const itemData = item as Record<string, unknown>;
    if (
      typeof itemData.productId !== "string" ||
      itemData.productId.trim() === "" ||
      typeof itemData.title !== "string" ||
      itemData.title.trim() === "" ||
      typeof itemData.quantity !== "number" ||
      !Number.isInteger(itemData.quantity) ||
      itemData.quantity <= 0 ||
      typeof itemData.unitPrice !== "number" ||
      !Number.isFinite(itemData.unitPrice) ||
      itemData.unitPrice <= 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Cada artículo debe tener producto, título, cantidad y precio válidos.",
      );
    }

    return {
      productId: itemData.productId,
      title: itemData.title,
      quantity: itemData.quantity,
      unitPrice: itemData.unitPrice,
    };
  });
}
