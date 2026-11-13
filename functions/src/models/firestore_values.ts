import {Timestamp} from "firebase-admin/firestore";
import type {DocumentData, DocumentReference} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";

/**
 * Reads a required string, optionally falling back to a legacy field name.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @param {string} [fallback] Value to use when the field is absent.
 * @return {string} Decoded string value.
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
 * Reads an optional string, optionally falling back to a legacy field name.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @return {string | undefined} Decoded string, if present.
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
 * Reads a required boolean, optionally falling back to a legacy field name.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @return {boolean} Decoded boolean value.
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
 * Reads a required number, optionally falling back to a legacy field name.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @return {number} Decoded finite number.
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
 * Reads an optional number, optionally falling back to a legacy field name.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @return {number | undefined} Decoded finite number, if present.
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
 * Reads a Firestore timestamp or JavaScript date into a CoreDate.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @return {CoreDate} Decoded date.
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
 * Reads an optional Firestore timestamp or JavaScript date.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @return {CoreDate | undefined} Decoded date, if present.
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
 * Reads an optional Firestore document reference.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Field containing the reference.
 * @param {string} [legacyField] Previous field name.
 * @return {DocumentReference | undefined} Decoded reference, if present.
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
 * Reads a required Firestore document reference.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Field containing the reference.
 * @param {string} [legacyField] Previous field name.
 * @return {DocumentReference} Decoded reference.
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
 * Reads an optional boolean from Firestore data.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Field name.
 * @return {boolean | undefined} Decoded boolean, if present.
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
 * Reads an enum value and rejects values outside the supported schema.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Field name.
 * @param {Array} values Supported enum values.
 * @param {string} [legacyField] Previous field name.
 * @return {string} Validated enum value.
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
 * Reads the Firestore document id as the canonical uid when available.
 * @param {DocumentData} data Firestore document data.
 * @param {string} [documentId] Firestore document id.
 * @return {string} Document uid.
 */
export function readUid(data: DocumentData, documentId?: string): string {
  return documentId ?? readString(data, "uid");
}

/**
 * Reads the canonical field or its legacy alias.
 * @param {DocumentData} data Firestore document data.
 * @param {string} field Canonical field name.
 * @param {string} [legacyField] Previous field name.
 * @return {*} Field value.
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
 * Checks whether an unknown value is a Firestore document reference.
 * @param {*} value Value to check.
 * @return {boolean} Whether the value is a document reference.
 */
function isDocumentReference(value: unknown): value is DocumentReference {
  return typeof value === "object" &&
    value !== null &&
    "path" in value &&
    typeof value.path === "string" &&
    "get" in value &&
    typeof value.get === "function";
}
