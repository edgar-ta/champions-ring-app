import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {
  DAY_MS,
  MEMBERSHIPS,
  MP_ACCESS_TOKEN,
  MP_TIMEOUT_MS,
  type MembershipType,
} from "../../core/utils/constants.js";

export interface MercadoPagoPreapproval {
  id?: string;
  status?: string;
  external_reference?: string;
  next_payment_date?: string;
  init_point?: string;
  sandbox_init_point?: string;
  message?: string;
  code?: string;
}

export interface MercadoPagoAuthorizedPayment {
  id?: number | string;
  preapproval_id?: string;
  transaction_amount?: number;
  currency_id?: string;
  status?: string;
  payment?: {id?: number | string; status?: string};
}

/**
 * Indica si el valor recibido es un tipo de membresía válido.
 *
 * @param {unknown} value Valor enviado por el cliente.
 * @return {boolean} true si existe en MEMBERSHIPS.
 */
export function isMembershipType(value: unknown): value is MembershipType {
  return (
    typeof value === "string" &&
    Object.prototype.hasOwnProperty.call(MEMBERSHIPS, value)
  );
}

/**
 * Calcula los campos del usuario que activan o extienden su membresía.
 *
 * @param {MembershipType} type Tipo de membresía pagada.
 * @param {unknown} currentExpiry Valor actual de membership_expires_at.
 * @return {Record<string, unknown>} Campos para actualizar users/{uid}.
 */
export function membershipActivation(
  type: MembershipType,
  currentExpiry: unknown,
): Record<string, unknown> {
  const membership = MEMBERSHIPS[type];
  const oldExpiry =
    currentExpiry instanceof Timestamp ? currentExpiry.toMillis() : 0;

  // Si la membresía sigue vigente se extiende desde su vencimiento;
  // si ya venció, comienza desde el momento del pago.
  const base = Math.max(Date.now(), oldExpiry);

  return {
    membership_plan_id: membership.planId,
    membership_type: type,
    membership_status: "active",
    membership_expires_at: Timestamp.fromMillis(
      base + membership.days * DAY_MS,
    ),
    updated_at: FieldValue.serverTimestamp(),
  };
}

/**
 * Llama a la API de Mercado Pago con el access token del vendedor.
 *
 * @param {string} path Ruta de la API, p. ej. "/preapproval".
 * @param {object} options Método, cuerpo y clave de idempotencia.
 * @return {Promise<object>} Código HTTP y cuerpo JSON de la respuesta.
 */
export async function mercadoPagoApi<T>(
  path: string,
  options: {
    method?: "GET" | "POST" | "PUT";
    body?: unknown;
    idempotencyKey?: string;
  } = {},
): Promise<{ ok: boolean; status: number; data: T }> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${MP_ACCESS_TOKEN.value()}`,
  };
  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  if (options.idempotencyKey) {
    headers["X-Idempotency-Key"] = options.idempotencyKey;
  }

  const response = await fetch(`https://api.mercadopago.com${path}`, {
    method: options.method ?? "GET",
    headers,
    signal: AbortSignal.timeout(MP_TIMEOUT_MS),
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  const data = (await response.json().catch(() => ({}))) as T;

  return {ok: response.ok, status: response.status, data};
}

/**
 * Convierte una fecha ISO de Mercado Pago en Timestamp.
 *
 * @param {unknown} value Fecha en texto (o nada).
 * @return {Timestamp | null} Timestamp, o null si no es válida.
 */
export function timestampFromIso(value: unknown): Timestamp | null {
  if (typeof value !== "string") return null;
  const millis = Date.parse(value);
  return Number.isNaN(millis) ? null : Timestamp.fromMillis(millis);
}

/**
 * Devuelve el primer valor de un parámetro que puede venir repetido.
 *
 * @param {unknown} value Valor de req.query o req.body.
 * @return {string | undefined} Primer valor como texto.
 */
export function firstValue(value: unknown): string | undefined {
  const first = Array.isArray(value) ? value[0] : value;
  if (first === undefined || first === null || first === "") {
    return undefined;
  }
  return String(first);
}
