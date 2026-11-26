import type {DocumentReference} from "firebase-admin/firestore";
import {Timestamp} from "firebase-admin/firestore";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

const MILLISECONDS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Calcula la fecha de término a partir del inicio y la duración del plan.
 * @param {number} startDateMillis Fecha de inicio en milisegundos.
 * @param {unknown} duration Duración serializada del plan.
 * @return {number} Fecha de término en milisegundos.
 */
export function calculateRenewalEndDate(
  startDateMillis: number,
  duration: unknown,
): number {
  if (!Number.isFinite(startDateMillis)) {
    throw new TypeError("The renewal start date must be a valid timestamp.");
  }

  let durationInDays: number;
  switch (duration) {
  case "1d":
    throw new Error(`Unsupported membership plan renewal ${String(duration)}`);
  case "1w":
    durationInDays = 7;
    break;
  case "1m":
    durationInDays = 30;
    break;
  default:
    throw new RangeError(
      `Unknown membership plan duration "${String(duration)}".`,
    );
  }

  return startDateMillis + durationInDays * MILLISECONDS_PER_DAY;
}

export const addRenewalEndDate = onDocumentCreated(
  {
    document: "members/{memberId}/renewals/{renewalId}",
    database: "default",
    maxInstances: 10,
  },
  async (event) => {
    const renewalSnapshot = event.data;
    if (!renewalSnapshot) {
      throw new Error("The created renewal document is missing.");
    }

    const membershipPlanRef: unknown =
      renewalSnapshot.get("membershipPlanRef");
    if (!isDocumentReference(membershipPlanRef)) {
      throw new Error("The renewal has no membership plan reference.");
    }

    const membershipPlanSnapshot = await membershipPlanRef.get();
    if (!membershipPlanSnapshot.exists) {
      throw new Error(
        `Membership plan "${membershipPlanRef.path}" was not found.`,
      );
    }

    const startDate: unknown = renewalSnapshot.get("startDate");
    if (!isTimestampLike(startDate)) {
      throw new TypeError(
        "The renewal start date must be a Firestore timestamp.",
      );
    }

    const endDateMillis = calculateRenewalEndDate(
      startDate.toMillis(),
      membershipPlanSnapshot.get("duration"),
    );

    return renewalSnapshot.ref.update({
      endDate: Timestamp.fromMillis(endDateMillis),
    });
  },
);

/**
 * Comprueba que un valor sea una referencia de documento Firestore.
 * @param {unknown} value Valor que se comprobará.
 * @return {boolean} Si el valor admite la operación get.
 */
function isDocumentReference(value: unknown): value is DocumentReference {
  return (
    typeof value === "object" &&
    value !== null &&
    "get" in value &&
    typeof value.get === "function"
  );
}

/**
 * Comprueba que un valor permita obtener su fecha en milisegundos.
 * @param {unknown} value Valor que se comprobará.
 * @return {boolean} Si el valor expone toMillis.
 */
function isTimestampLike(value: unknown): value is {toMillis(): number} {
  return (
    typeof value === "object" &&
    value !== null &&
    "toMillis" in value &&
    typeof value.toMillis === "function"
  );
}
