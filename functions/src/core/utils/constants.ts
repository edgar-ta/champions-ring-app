import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions";
import {defineSecret} from "firebase-functions/params";

setGlobalOptions({maxInstances: 10});
initializeApp();

export const REGION = "us-central1";
const DATABASE_ID = process.env.FIRESTORE_DATABASE_ID ?? "default";
export const db = DATABASE_ID === "(default)" ?
  getFirestore() :
  getFirestore(DATABASE_ID);
export {FieldValue, Timestamp};

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? "champions-ring-app";
const FUNCTIONS_BASE_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net`;
export const NOTIFICATION_URL = process.env.MP_NOTIFICATION_URL ??
  `${FUNCTIONS_BASE_URL}/mercadoPagoWebhook?source_news=webhooks`;
export const RETURN_URL = process.env.PAYMENT_RETURN_URL ??
  `${FUNCTIONS_BASE_URL}/paymentReturn`;
export const MP_ACCESS_TOKEN = defineSecret("MP_ACCESS_TOKEN");
export const MP_WEBHOOK_SECRET = defineSecret("MP_WEBHOOK_SECRET");
export const MP_ACCESS_TOKEN_V2 = defineSecret("MP_ACCESS_TOKEN_V2");
export const MP_WEBHOOK_SECRET_V2 = defineSecret("MP_WEBHOOK_SECRET_V2");

export const MEMBERSHIPS = {
  day: {amount: 69, days: 1, label: "Acceso por 1 d?a", planId: 1},
  week: {amount: 180, days: 7, label: "Acceso por 1 semana", planId: 2},
  month: {amount: 600, days: 30, label: "Acceso por 1 mes", planId: 3},
} as const;
export type MembershipType = keyof typeof MEMBERSHIPS;

export const REGISTRATION_FEE = 120;
export const RECURRING_TYPES: readonly MembershipType[] = ["week", "month"];
export const LIVE_SUBSCRIPTION_STATUSES: readonly string[] = [
  "authorized",
  "paused",
];
export const REUSE_WINDOW_MS = 30 * 60 * 1000;
export const MP_TIMEOUT_MS = 15 * 1000;
export const DAY_MS = 24 * 60 * 60 * 1000;
export const REVERSAL_STATUSES: readonly string[] = [
  "refunded",
  "charged_back",
  "cancelled",
];
export const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
