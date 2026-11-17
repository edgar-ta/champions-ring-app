import type {DocumentReference} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {CoreDate} from "../core/models/core_date.js";
import {CorePayment} from "../core/models/core_payment.js";
import {
  CoreClientRepository,
} from "../core/repositories/core_client_repository.js";
import {
  CorePaymentRepository,
} from "../core/repositories/core_payment_repository.js";
import {
  db,
  MP_ACCESS_TOKEN,
  NOTIFICATION_URL,
  REGION,
  REUSE_WINDOW_MS,
  RETURN_URL,
  USE_SANDBOX,
} from "../core/utils/constants.js";
import {MercadoPagoPayment} from "../shared/models/payment.js";
import type {SimpleItem} from "../shared/models/simple_item.js";
import {mercadoPagoApi} from "../shared/utils/shared.js";

type CheckoutItem = Pick<
  SimpleItem,
  "productId" | "title" | "quantity" | "unitPrice"
>;

interface MercadoPagoPreference {
  id?: string;
  init_point?: string;
  sandbox_init_point?: string;
}

/**
 * Registra un documento de tipo `mercado-pago` en la colección `payments`.
 *
 * El cuerpo de la solicitud requiere los siguientes parámetros:
 * - `paymentUid: string`. La id única a la cual estará asociada el
 *   pago a crear.
 * - `simpleItems: SimpleItem[]`. La lista de ítems para los cuales
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
  {region: REGION, secrets: [MP_ACCESS_TOKEN]},
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
    if (typeof clientUid === "string") {
      const clientRepository = new CoreClientRepository(db);
      if (!(await clientRepository.isDocumentPresent(clientUid))) {
        throw new HttpsError(
          "invalid-argument",
          "El cliente especificado no existe.",
        );
      }
      payerRef = clientRepository.collection.doc(clientUid);
    }

    const amount = Math.round(
      items.reduce((total, item) => total + item.quantity * item.unitPrice, 0) *
        100,
    ) / 100;

    if (!Number.isFinite(amount) || amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "El monto del pago debe ser mayor que cero.",
      );
    }

    const paymentRepository = new CorePaymentRepository(db);
    const existingSnapshot = await paymentRepository.collection
      .doc(paymentUid)
      .get();
    if (existingSnapshot.exists) {
      const existingDocument = existingSnapshot.data();
      if (existingDocument === undefined) {
        throw new HttpsError(
          "internal",
          "No fue posible leer el pago existente.",
        );
      }

      const existingPayment = CorePayment.fromFirestore(
        existingDocument,
        existingSnapshot.id,
      );
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
        existingPayment.status === "pending" &&
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
        existingPayment.status !== "checkout_creation_failed" &&
        existingPayment.status !== "pending"
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
      checkoutUrl: "",
      status: "pending",
      preferenceId: "",
    });

    await paymentRepository.upsert(payment.toCorePayment());

    let response: {
      ok: boolean;
      status: number;
      data: MercadoPagoPreference;
    };

    try {
      response = await mercadoPagoApi<MercadoPagoPreference>(
        "/checkout/preferences",
        {
          method: "POST",
          idempotencyKey: paymentUid,
          body: {
            items: items.map((item) => ({
              id: item.productId,
              title: item.title,
              quantity: item.quantity,
              currency_id: "MXN",
              unit_price: item.unitPrice,
            })),
            external_reference: paymentUid,
            notification_url: NOTIFICATION_URL,
            back_urls: {
              success: `${RETURN_URL}/success`,
              pending: `${RETURN_URL}/pending`,
              failure: `${RETURN_URL}/failure`,
            },
            auto_return: "approved",
            statement_descriptor: "Champion's Ring",
          },
        },
      );
    } catch (error) {
      logger.error("No se pudo contactar a Mercado Pago", error);
      await paymentRepository.upsert(
        payment
          .copyWith({status: "checkout_creation_failed"})
          .toCorePayment(),
      );
      throw new HttpsError(
        "unavailable",
        "No fue posible conectar con Mercado Pago. Intenta de nuevo.",
      );
    }

    const preference = response.data;
    if (
      !response.ok ||
      typeof preference.id !== "string" ||
      preference.id === "" ||
      typeof preference.init_point !== "string" ||
      preference.init_point === ""
    ) {
      logger.error("Error al crear preferencia de pago", {
        status: response.status,
        response: preference,
      });
      await paymentRepository.upsert(
        payment
          .copyWith({status: "checkout_creation_failed"})
          .toCorePayment(),
      );
      throw new HttpsError("internal", "No fue posible iniciar el pago.");
    }

    const checkoutUrl = USE_SANDBOX ?
      preference.sandbox_init_point ?? preference.init_point :
      preference.init_point;

    await paymentRepository.upsert(
      payment
        .copyWith({
          checkoutUrl,
          preferenceId: preference.id,
        })
        .toCorePayment(),
    );

    return {checkoutUrl};
  },
);

/**
 * Valida los campos del artículo sin consultar un catálogo confiable.
 * @param {unknown} value Valor recibido en la solicitud.
 * @return {CheckoutItem[]} Artículos validados para el checkout.
 */
function parseSimpleItems(value: unknown): CheckoutItem[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Debes incluir al menos un artículo para el pago.",
    );
  }

  return value.map((item): CheckoutItem => {
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
