import {
  MP_ACCESS_TOKEN_V2,
  MP_TIMEOUT_MS,
  NOTIFICATION_URL,
  RETURN_URL,
} from "../../core/utils/constants.js";
import {asRecord, optionalString} from "./shared.js";
import type {
  CreateOrderRequest,
  MercadoPagoOrder,
  MercadoPagoOrderItem,
  RegisterOrderInput,
  RegisteredOrder,
} from "../models/register_order.js";

/**
 * Crea una orden de Checkout Pro mediante la Orders API.
 *
 * Esta función es un helper de servidor; no expone una función HTTP ni debe
 * ejecutarse en una aplicación cliente.
 * @param {RegisterOrderInput} input Datos de pago y comprador.
 * @return {Promise<RegisteredOrder>} ID y URL de checkout de la orden.
 */
export async function registerOrder(
  input: RegisterOrderInput,
): Promise<RegisteredOrder> {
  if (
    input.paymentUid.trim() === "" ||
    input.paymentUid.includes("/") ||
    input.items.length === 0
  ) {
    throw new TypeError("La UID y los artículos de la orden son obligatorios.");
  }

  if (input.payer && input.payer.email.trim() === "") {
    throw new TypeError("El correo del comprador no es válido.");
  }
  if (
    input.paymentMethod?.maxInstallments !== undefined &&
    (!Number.isInteger(input.paymentMethod.maxInstallments) ||
      input.paymentMethod.maxInstallments < 1 ||
      input.paymentMethod.maxInstallments > 36)
  ) {
    throw new TypeError("El máximo de cuotas debe estar entre 1 y 36.");
  }

  const totalCents = input.items.reduce((total, item) => {
    if (
      item.productId.trim() === "" ||
      item.title.trim() === "" ||
      !Number.isInteger(item.quantity) ||
      item.quantity <= 0 ||
      !Number.isFinite(item.unitPrice) ||
      item.unitPrice <= 0
    ) {
      throw new TypeError("La orden contiene un artículo no válido.");
    }

    const unitPriceCents = Math.round(item.unitPrice * 100);
    if (!Number.isSafeInteger(unitPriceCents) || unitPriceCents <= 0) {
      throw new TypeError("El precio del artículo no es válido.");
    }
    return total + unitPriceCents * item.quantity;
  }, 0);

  if (!Number.isSafeInteger(totalCents) || totalCents <= 0) {
    throw new TypeError("El monto de la orden debe ser mayor que cero.");
  }

  const amount = (totalCents / 100).toFixed(2);
  const body: CreateOrderRequest = {
    type: "online",
    processing_mode: "manual",
    capture_mode: "automatic_async",
    total_amount: amount,
    currency: "MXN",
    external_reference: input.paymentUid,
    description: "Compra en Champions Ring",
    payer: input.payer ? {
      email: input.payer.email,
      first_name: input.payer.firstName,
      last_name: input.payer.lastName,
      identification: input.payer.identification,
      phone: input.payer.phone,
      address: input.payer.address,
    } : undefined,
    items: input.items.map((item) => ({
      external_code: item.productId,
      title: item.title,
      description: item.description,
      category_id: item.categoryId,
      picture_url: item.pictureUrl,
      quantity: item.quantity,
      unit_price: (Math.round(item.unitPrice * 100) / 100).toFixed(2),
      type: item.type,
      warranty: item.warranty,
      unit_measure: item.unitMeasure,
    })),
    additional_info: input.additionalInfo,
    shipment: input.shipment ? {
      mode: input.shipment.mode,
      local_pickup: input.shipment.localPickup,
      cost: input.shipment.cost?.toFixed(2),
      free_shipping: input.shipment.freeShipping,
      address: input.shipment.address && {
        zip_code: input.shipment.address.zipCode,
        street_name: input.shipment.address.streetName,
        street_number: input.shipment.address.streetNumber,
        floor: input.shipment.address.floor,
        apartment: input.shipment.address.apartment,
        neighborhood: input.shipment.address.neighborhood,
        city: input.shipment.address.city,
        state: input.shipment.address.state,
        complement: input.shipment.address.complement,
        country: input.shipment.address.country,
      },
    } : undefined,
    integration_data: input.integrationData ? {
      integrator_id: input.integrationData.integratorId,
      platform_id: input.integrationData.platformId,
      corporation_id: input.integrationData.corporationId,
    } : undefined,
    config: {
      statement_descriptor: "CHAMPIONS",
      online: {
        callback_url: NOTIFICATION_URL,
        success_url: `${RETURN_URL}/success`,
        pending_url: `${RETURN_URL}/pending`,
        failure_url: `${RETURN_URL}/failure`,
        auto_return: "approved",
      },
      payment_method: input.paymentMethod && {
        max_installments: input.paymentMethod.maxInstallments,
        not_allowed_ids: input.paymentMethod.notAllowedIds,
        not_allowed_types: input.paymentMethod.notAllowedTypes,
      },
    },
  };
  const result = await mercadoPagoOrdersApi(
    "/v1/orders",
    {method: "POST", body, idempotencyKey: input.paymentUid},
  );

  const resultData = asRecord(result);
  if (
    resultData === null ||
    typeof resultData.id !== "string" ||
    resultData.id === "" ||
    typeof resultData.checkout_url !== "string" ||
    resultData.checkout_url === ""
  ) {
    throw new Error("Mercado Pago no devolvió el ID y URL de la orden.");
  }

  return {id: resultData.id, checkoutUrl: resultData.checkout_url};
}

/**
 * Recupera una orden de Checkout Pro mediante la Orders API.
 * @param {string} orderId Identificador de la order.
 * @return {Promise<MercadoPagoOrder>} Order recuperada.
 */
export async function recuperarOrder(
  orderId: string,
): Promise<MercadoPagoOrder> {
  if (orderId.trim() === "" || orderId.includes("/")) {
    throw new TypeError("El identificador de la order no es válido.");
  }

  const response = await mercadoPagoOrdersApi(
    `/v1/orders/${encodeURIComponent(orderId)}`,
  );
  const responseData = asRecord(response);
  if (responseData === null || typeof responseData.id !== "string") {
    throw new Error("Mercado Pago devolvió una order no válida.");
  }
  if (responseData.id !== orderId) {
    throw new Error("Mercado Pago no devolvió la order solicitada.");
  }

  return {
    id: responseData.id,
    external_reference: optionalString(responseData.external_reference),
    status: optionalString(responseData.status),
    status_detail: optionalString(responseData.status_detail),
    items: parseOrderItems(responseData.items),
  };
}

/**
 * Ejecuta una solicitud autenticada a la Orders API.
 * @param {string} path Ruta del endpoint de orders.
 * @param {object} options Método, cuerpo e idempotencia de la solicitud.
 * @return {Promise<unknown>} JSON devuelto por Mercado Pago.
 */
async function mercadoPagoOrdersApi(
  path: string,
  options: {
    method?: "GET" | "POST";
    body?: CreateOrderRequest;
    idempotencyKey?: string;
  } = {},
): Promise<unknown> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${MP_ACCESS_TOKEN_V2.value()}`,
  };
  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  if (options.idempotencyKey !== undefined) {
    headers["X-Idempotency-Key"] = options.idempotencyKey;
  }

  const response = await fetch(`https://api.mercadopago.com${path}`, {
    method: options.method ?? "GET",
    headers,
    signal: AbortSignal.timeout(MP_TIMEOUT_MS),
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  if (!response.ok) {
    throw new Error(
      `Mercado Pago respondió con HTTP ${response.status} para Orders API.`,
    );
  }
  const data: unknown = await response.json();
  return data;
}

/**
 * Valida la lista de artículos de una order devuelta por Mercado Pago.
 * @param {unknown} value Lista de artículos recibida.
 * @return {Array<MercadoPagoOrderItem> | undefined} Artículos validados.
 */
function parseOrderItems(
  value: unknown,
): MercadoPagoOrderItem[] | undefined {
  if (value === undefined || value === null) return undefined;
  if (!Array.isArray(value)) {
    throw new TypeError(
      "Mercado Pago devolvió una lista de artículos no válida.",
    );
  }

  return value.map((item) => {
    const itemData = asRecord(item);
    if (itemData === null) {
      throw new TypeError("Mercado Pago devolvió un artículo no válido.");
    }
    return {external_code: optionalString(itemData.external_code)};
  });
}

/**
 * Obtiene y valida el UID del pago asociado a la order.
 * @param {MercadoPagoOrder} order Order vigente de Mercado Pago.
 * @return {string} UID del pago asociado.
 */
export function getPaymentUid(order: MercadoPagoOrder): string {
  const paymentUid = order.external_reference;
  if (
    typeof paymentUid !== "string" ||
    paymentUid.trim() === "" ||
    paymentUid.includes("/")
  ) {
    throw new TypeError("La order no incluye una referencia externa válida.");
  }
  return paymentUid;
}
