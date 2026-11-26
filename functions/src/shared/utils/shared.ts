/**
 * Comprueba que un valor sea un objeto JSON.
 * @param {unknown} value Valor recibido.
 * @return {Record<string, unknown> | null} Objeto o null si no lo es.
 */
export function asRecord(value: unknown): Record<string, unknown> | null {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

/**
 * Valida un campo opcional de texto devuelto por Mercado Pago.
 * @param {unknown} value Campo recibido.
 * @return {string | undefined} Texto validado o undefined si no está presente.
 */
export function optionalString(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") {
    throw new TypeError("Mercado Pago devolvió un campo de order no válido.");
  }
  return value;
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
