import {MercadoPagoConfig, Order} from "mercadopago";
import {
  MP_ACCESS_TOKEN_V2,
  MP_TIMEOUT_MS,
  NOTIFICATION_URL,
  RETURN_URL,
} from "../../core/utils/constants.js";
import type {
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

  const client = new MercadoPagoConfig({
    accessToken: MP_ACCESS_TOKEN_V2.value(),
    options: {timeout: MP_TIMEOUT_MS},
  });
  const order = new Order(client);
  const amount = (totalCents / 100).toFixed(2);
  const result = await order.create({
    body: {
      type: "online",
      processing_mode: "automatic",
      capture_mode: "automatic",
      total_amount: amount,
      currency: "MXN",
      external_reference: input.paymentUid,
      description: "Compra en Champions Ring",
      payer: input.payer && {
        email: input.payer.email,
        first_name: input.payer.firstName,
        last_name: input.payer.lastName,
        identification: input.payer.identification,
        phone: input.payer.phone,
        address: input.payer.address,
      },
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
      shipment: input.shipment && {
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
      },
      integration_data: input.integrationData && {
        integrator_id: input.integrationData.integratorId,
        platform_id: input.integrationData.platformId,
        corporation_id: input.integrationData.corporationId,
      },
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
    },
    requestOptions: {idempotencyKey: input.paymentUid},
  });

  if (
    typeof result.id !== "string" ||
    result.id === "" ||
    typeof result.checkout_url !== "string" ||
    result.checkout_url === ""
  ) {
    throw new Error("Mercado Pago no devolvió el ID y URL de la orden.");
  }

  return {id: result.id, checkoutUrl: result.checkout_url};
}
