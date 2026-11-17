import {Timestamp} from "firebase-admin/firestore";
import type {DocumentData, DocumentReference} from "firebase-admin/firestore";
import {CoreDate} from "../models/core_date.js";

/**
 * Lee un texto obligatorio y puede usar el nombre de campo heredado.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @param {string} [fallback] Valor usado cuando el campo no está presente.
 * @return {string} Texto decodificado.
 */
export function readString(
  data: DocumentData,
  field: string,
  legacyField?: string,
  fallback?: string
): string {
  const value = readValue(data, field, legacyField);
  if (typeof value === "string") {
    return value;
  }
  if (value === undefined && fallback !== undefined) {
    return fallback;
  }
  throw new TypeError(`Firestore field "${field}" must be a string.`);
}

/**
 * Lee un texto opcional y, de ser necesario, usa el nombre de campo heredado.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {string | undefined} Texto decodificado, si está presente.
 */
export function readOptionalString(
  data: DocumentData,
  field: string,
  legacyField?: string
): string | undefined {
  const value = readValue(data, field, legacyField);
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "string") {
    throw new TypeError(`Firestore field "${field}" must be a string.`);
  }
  return value;
}

/**
 * Lee un booleano obligatorio y puede usar el nombre de campo heredado.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {boolean} Valor booleano decodificado.
 */
export function readBoolean(
  data: DocumentData,
  field: string,
  legacyField?: string
): boolean {
  const value = readValue(data, field, legacyField);
  if (typeof value !== "boolean") {
    throw new TypeError(`Firestore field "${field}" must be a boolean.`);
  }
  return value;
}

/**
 * Lee un número obligatorio y puede usar el nombre de campo heredado.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {number} Número finito decodificado.
 */
export function readNumber(
  data: DocumentData,
  field: string,
  legacyField?: string
): number {
  const value = readValue(data, field, legacyField);
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new TypeError(`Firestore field "${field}" must be a finite number.`);
  }
  return value;
}

/**
 * Lee un número opcional y puede usar el nombre de campo heredado.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {number | undefined} Número finito decodificado, si está presente.
 */
export function readOptionalNumber(
  data: DocumentData,
  field: string,
  legacyField?: string
): number | undefined {
  const value = readValue(data, field, legacyField);
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new TypeError(`Firestore field "${field}" must be a finite number.`);
  }
  return value;
}

/**
 * Lee una marca de tiempo o fecha de JavaScript y la convierte a CoreDate.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {CoreDate} Fecha decodificada.
 */
export function readDate(
  data: DocumentData,
  field: string,
  legacyField?: string
): CoreDate {
  const value = readValue(data, field, legacyField);
  if (value instanceof Timestamp) {
    return CoreDate.fromTimestamp(value);
  }
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return CoreDate.fromDateTime(value);
  }
  throw new TypeError(
    `Firestore field "${field}" must be a date or Timestamp.`
  );
}

/**
 * Lee una marca de tiempo o fecha de JavaScript opcional.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {CoreDate | undefined} Fecha decodificada, si está presente.
 */
export function readOptionalDate(
  data: DocumentData,
  field: string,
  legacyField?: string
): CoreDate | undefined {
  const value = readValue(data, field, legacyField);
  if (value === undefined || value === null) {
    return undefined;
  }
  if (value instanceof Timestamp) {
    return CoreDate.fromTimestamp(value);
  }
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return CoreDate.fromDateTime(value);
  }
  throw new TypeError(
    `Firestore field "${field}" must be a date or Timestamp.`
  );
}

/**
 * Lee una referencia opcional a un documento de Firestore.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Campo que contiene la referencia.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {DocumentReference | undefined} Referencia decodificada, si existe.
 */
export function readOptionalReference(
  data: DocumentData,
  field: string,
  legacyField?: string
): DocumentReference | undefined {
  const value = readValue(data, field, legacyField);
  if (value === undefined || value === null) {
    return undefined;
  }
  if (isDocumentReference(value)) {
    return value;
  }
  throw new TypeError(
    `Firestore field "${field}" must be a document reference.`
  );
}

/**
 * Lee una referencia obligatoria a un documento de Firestore.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Campo que contiene la referencia.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {DocumentReference} Referencia decodificada.
 */
export function readReference(
  data: DocumentData,
  field: string,
  legacyField?: string
): DocumentReference {
  const value = readOptionalReference(data, field, legacyField);
  if (value === undefined) {
    throw new TypeError(`Firestore field "${field}" is required.`);
  }
  return value;
}

/**
 * Lee un booleano opcional de los datos de Firestore.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre del campo.
 * @return {boolean | undefined} Booleano decodificado, si está presente.
 */
export function readOptionalBoolean(
  data: DocumentData,
  field: string
): boolean | undefined {
  const value = data[field];
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "boolean") {
    throw new TypeError(`Firestore field "${field}" must be a boolean.`);
  }
  return value;
}

/**
 * Lee un valor de enumeración y rechaza valores fuera del esquema admitido.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre del campo.
 * @param {Array} values Valores admitidos de la enumeración.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {string} Valor de enumeración validado.
 */
export function readEnum<const Value extends string>(
  data: DocumentData,
  field: string,
  values: readonly Value[],
  legacyField?: string
): Value {
  const value = readValue(data, field, legacyField);
  if (
    typeof value === "string" &&
    values.some((candidate) => candidate === value)
  ) {
    return value as Value;
  }
  throw new TypeError(
    `Firestore field "${field}" must be one of: ${values.join(", ")}.`
  );
}

/**
 * Lee el ID del documento como UID cuando está disponible.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} [documentId] ID del documento de Firestore.
 * @return {string} UID del documento.
 */
export function readUid(data: DocumentData, documentId?: string): string {
  return documentId ?? readString(data, "uid");
}

/**
 * Lee el campo actual o su alias heredado.
 * @param {DocumentData} data Datos del documento de Firestore.
 * @param {string} field Nombre actual del campo.
 * @param {string} [legacyField] Nombre anterior del campo.
 * @return {*} Valor del campo.
 */
function readValue(
  data: DocumentData,
  field: string,
  legacyField?: string
): unknown {
  if (
    (data[field] !== undefined && data[field] !== null) ||
    legacyField === undefined
  ) {
    return data[field];
  }
  return data[legacyField];
}

/**
 * Comprueba si un valor desconocido es una referencia de documento Firestore.
 * @param {*} value Valor que se comprobará.
 * @return {boolean} Indica si el valor es una referencia de documento.
 */
function isDocumentReference(value: unknown): value is DocumentReference {
  return typeof value === "object" &&
    value !== null &&
    "path" in value &&
    typeof value.path === "string" &&
    "get" in value &&
    typeof value.get === "function";
}
