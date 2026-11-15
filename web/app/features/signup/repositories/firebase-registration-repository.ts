import { FirebaseError, deleteApp, initializeApp } from "firebase/app";
import { createUserWithEmailAndPassword, inMemoryPersistence, initializeAuth, sendPasswordResetEmail, signOut } from "firebase/auth";
import { doc, getDoc, getDocs, getFirestore, limit, query, serverTimestamp, setDoc, Timestamp, updateDoc, where, writeBatch, type Firestore } from "firebase/firestore";
import { getDownloadURL, getStorage, ref, uploadBytes, type FirebaseStorage } from "firebase/storage";

import { DURATION_DAYS, INSCRIPTION_FEE } from "@/app/core/constants/membership";
import { clientsCollection, COLLECTIONS, membersCollection, membershipPlansCollection, paymentsCollection } from "@/app/core/firebase/collections";
import { auth, DATABASE_ID, db, firebaseConfig } from "@/app/core/firebase/firebase";
import type { Client } from "@/app/core/models/client";
import { isMinor, type PaymentDetails, type PersonalData, type PlanCatalog } from "../models/registration";
import { buildWaiverPdf } from "../services/waiver-pdf";
import type { RegistrationRepository } from "./registration-repository";

/** Error con un mensaje listo para mostrarle a la recepcionista. */
export class RegistrationError extends Error {}

const normalizeEmail = (value: string) => value.trim().toLowerCase();
const normalizeName = (value: string) => value.trim().replace(/\s+/g, " ");
const DAY_MS = 24 * 60 * 60 * 1000;

async function findClientByEmail(email: string): Promise<Client | null> {
  // Los correos nuevos se guardan en minúsculas; también se busca tal como se escribió
  // por si un registro anterior (p. ej. desde la app) lo guardó con mayúsculas.
  const candidates = [...new Set([normalizeEmail(email), email.trim()])];
  const snapshot = await getDocs(query(clientsCollection(), where("email", "in", candidates), limit(10)));
  return snapshot.docs.map(document => ({ ...document.data(), uid: document.data().uid ?? document.id })).find(client => client.deletionDate == null) ?? null;
}

/** Cliente nuevo creado por la recepcionista, con id generado (prospecto o visita). */
async function createClient(personal: PersonalData, withSampleClass: boolean): Promise<Client> {
  const reference = doc(clientsCollection());
  const fields = { uid: reference.id, name: normalizeName(personal.name), lastName: normalizeName(personal.lastName), email: normalizeEmail(personal.email) };
  // Los campos nulables que no aplican se omiten: las reglas exigen que, si vienen, sean timestamp.
  await setDoc(reference, { ...fields, ...(withSampleClass ? { sampleClassDate: serverTimestamp() } : {}), creationDate: serverTimestamp() });
  const now = Timestamp.now();
  return { ...fields, ...(withSampleClass ? { sampleClassDate: now } : {}), creationDate: now };
}

/** Registra el pago con la sesión de la recepcionista (solo ella puede aprobar efectivo y transferencia). */
async function createPayment(clientUid: string, receptionistUid: string, amount: number, details: PaymentDetails): Promise<{ id: string; approved: boolean }> {
  const reference = doc(paymentsCollection());
  const base = { uid: reference.id, type: details.type, amount, currency: "MXN" as const, payerRef: doc(clientsCollection(), clientUid), creationDate: serverTimestamp() };
  const approval = { approverRef: doc(db, COLLECTIONS.receptionists, receptionistUid), approvalDate: serverTimestamp() };
  switch (details.type) {
    case "cash":
      await setDoc(reference, { ...base, ...approval });
      return { id: reference.id, approved: true };
    case "direct-transfer":
      await setDoc(reference, {
        ...base,
        referenceId: details.referenceId.trim(),
        issuingEntity: details.issuingEntity,
        ...(details.issuingEntity === "other" ? { issuingEntityName: details.issuingEntityName?.trim() ?? "" } : {}),
        ...approval,
      });
      return { id: reference.id, approved: true };
    case "mercado-pago":
      // Sin approverRef ni approvalDate: lo confirma el servidor con la API de Mercado Pago.
      await setDoc(reference, { ...base, mercadoPagoPaymentId: details.mercadoPagoPaymentId.trim() });
      return { id: reference.id, approved: false };
  }
}

const EXTENSIONS: Record<string, string> = { "image/jpeg": "jpg", "image/png": "png", "image/webp": "webp" };

/** Mismas rutas que la app (UserStorageService): users/{uid}/... */
async function upload(storage: FirebaseStorage, uid: string, name: string, file: Blob, contentType: string): Promise<string> {
  const extension = contentType === "application/pdf" ? "pdf" : EXTENSIONS[contentType];
  if (!extension) throw new RegistrationError("Uno de los archivos tiene un formato no compatible (usa JPG, PNG o WEBP).");
  const path = `users/${uid}/${name}.${extension}`;
  const reference = ref(storage, path);
  try {
    await uploadBytes(reference, file, { contentType });
    return await getDownloadURL(reference);
  } catch (error) {
    // Se indica qué archivo falló para poder ajustar las reglas de Storage.
    if (error instanceof FirebaseError) throw new UploadError(path, contentType, error.code);
    throw error;
  }
}

class UploadError extends Error {
  constructor(readonly path: string, readonly contentType: string, readonly code: string) { super(`${code} en ${path}`); }
}

/** Sube todos los archivos; si alguno falla, el error dice cuáles fueron y por qué. */
async function uploadAll<T extends readonly unknown[]>(uploads: { [K in keyof T]: Promise<T[K]> }): Promise<T> {
  const results = await Promise.allSettled(uploads);
  const failures = results.flatMap(result => result.status === "rejected" ? [result.reason] : []);
  if (failures.length === 0) return results.map(result => (result as PromiseFulfilledResult<unknown>).value) as unknown as T;
  const uploadFailures = failures.filter((failure): failure is UploadError => failure instanceof UploadError);
  if (uploadFailures.length !== failures.length) throw failures.find(failure => !(failure instanceof UploadError));
  const denied = uploadFailures.filter(failure => failure.code === "storage/unauthorized");
  const detail = uploadFailures.map(failure => `${failure.path} (${failure.contentType})`).join(", ");
  throw new RegistrationError(denied.length > 0
    ? `Firebase Storage no permitió subir: ${detail}. Revisa las reglas de Storage para users/{uid}/.`
    : `No se pudieron subir: ${detail} (${uploadFailures[0].code}).`);
}

function registrationMessage(error: unknown): string | null {
  if (error instanceof RegistrationError) return error.message;
  if (!(error instanceof FirebaseError)) return null;
  switch (error.code) {
    case "auth/email-already-in-use": return "Ese correo ya tiene una cuenta en la app de Champions Ring. Usa otro correo o pide que inicie sesión con esa cuenta.";
    case "auth/invalid-email": return "El correo electrónico no es válido.";
    case "auth/network-request-failed": return "No se pudo crear la cuenta por un problema de conexión.";
    case "auth/operation-not-allowed": return "El inicio de sesión con correo y contraseña está desactivado en Firebase Authentication.";
  }
  return null;
}

function temporaryPassword(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
  return Array.from(crypto.getRandomValues(new Uint8Array(24)), byte => alphabet[byte % alphabet.length]).join("");
}

export const firebaseRegistrationRepository: RegistrationRepository = {
  async lookupEmail(email) {
    const client = await findClientByEmail(email);
    if (!client) return { client: null, isMember: false };
    const member = (await getDoc(doc(membersCollection(), client.uid))).data();
    return { client, isMember: !!member && member.deletionDate == null };
  },

  async listPlans() {
    const snapshot = await getDocs(membershipPlansCollection());
    const plans: PlanCatalog["plans"] = [];
    const ignored: PlanCatalog["ignored"] = [];
    for (const document of snapshot.docs) {
      const plan = document.data();
      // Se explica por qué se descarta cada documento, para que se pueda corregir en la consola.
      const reason = plan.deletionDate != null ? "está dado de baja (deletionDate)"
        : !(plan.duration in DURATION_DAYS) ? `duration es ${JSON.stringify(plan.duration ?? null)}; debe ser "1d", "1w" o "1m"`
        : typeof plan.cost !== "number" || !(plan.cost > 0) ? `cost es ${JSON.stringify(plan.cost ?? null)}; debe ser un número mayor que 0`
        : null;
      if (reason) ignored.push({ id: document.id, reason });
      else plans.push({ id: document.id, plan });
    }
    plans.sort((a, b) => DURATION_DAYS[a.plan.duration] - DURATION_DAYS[b.plan.duration]);
    return { plans, ignored };
  },

  registerSampleClass: (personal) => createClient(personal, true),

  async registerVisit({ personal, existing, plan, payment, receptionistUid }) {
    const client = existing ?? await createClient(personal, false);
    await createPayment(client.uid, receptionistUid, plan.plan.cost, payment);
  },

  async registerMember({ personal, existing, record, waiver, plan, payment, receptionistUid }) {
    // Instancia secundaria: crear la cuenta inicia sesión como el alumno, y así la sesión
    // de la recepcionista no se toca. Sin persistencia, para no dejar rastro en el navegador.
    const secondary = initializeApp(firebaseConfig, `registration-${crypto.randomUUID()}`);
    const memberAuth = initializeAuth(secondary, { persistence: inMemoryPersistence });
    const memberDb: Firestore = getFirestore(secondary, DATABASE_ID);
    const memberStorage = getStorage(secondary);
    const email = normalizeEmail(personal.email);
    const warnings: string[] = [];

    try {
      const credential = await createUserWithEmailAndPassword(memberAuth, email, temporaryPassword());
      const uid = credential.user.uid;
      const minor = isMinor(record.birthDate);

      // 1. Documentos y alta, como el propio alumno (las reglas de la app ya lo permiten).
      //    Si algo falla aquí, se borra la cuenta para poder reintentar con el mismo correo.
      try {
        // Para un menor, ine_front e ine_back son la INE de su tutor (el modelo solo tiene esos campos).
        const [photoUrl, ineFrontUrl, ineBackUrl, curpUrl, waiverAgreementUrl] = await uploadAll<[string, string, string, string | null, string]>([
          upload(memberStorage, uid, "profile_picture", record.photo, record.photo.type),
          upload(memberStorage, uid, "ine_front", record.ineFront, record.ineFront.type),
          upload(memberStorage, uid, "ine_back", record.ineBack, record.ineBack.type),
          minor && record.curp ? upload(memberStorage, uid, "curp", record.curp, record.curp.type) : Promise.resolve(null),
          buildWaiverPdf(personal, record, waiver).then(pdf => upload(memberStorage, uid, "liability_waiver", pdf, "application/pdf")),
        ]);

        const batch = writeBatch(memberDb);
        batch.set(doc(memberDb, COLLECTIONS.clients, uid), {
          uid,
          name: normalizeName(existing?.name ?? personal.name),
          lastName: normalizeName(existing?.lastName ?? personal.lastName),
          email,
          // Si era prospecto, conserva la fecha de su clase muestra.
          ...(existing?.sampleClassDate ? { sampleClassDate: existing.sampleClassDate } : {}),
          creationDate: serverTimestamp(),
        });
        batch.set(doc(memberDb, COLLECTIONS.members, uid), {
          uid,
          birthDate: Timestamp.fromDate(record.birthDate),
          phone: record.phone.trim(),
          photoUrl,
          legalDataAreTheirs: !minor,
          inscriptionPaid: false,
          membershipPlanRef: doc(memberDb, COLLECTIONS.membershipPlans, plan.id),
          ...(minor ? {
            guardianName: record.guardianName?.trim() ?? null,
            guardianPhone: record.guardianPhone?.trim() ?? null,
            guardianRelationship: record.guardianRelationship?.trim() ?? null,
          } : {}),
          ...(curpUrl ? { curpUrl, curpValidated: false } : {}),
          ineFrontUrl,
          ineFrontValidated: false,
          ineBackUrl,
          ineBackValidated: false,
          waiverAgreementUrl,
          waiverAgreementValidated: false,
          creationDate: serverTimestamp(),
        });
        await batch.commit();
      } catch (error) {
        await credential.user.delete().catch(() => undefined);
        throw error;
      }

      // A partir de aquí el alumno ya existe: los fallos se informan sin deshacer el registro.

      // 2. Si era prospecto o visita, su cliente anterior (con otro uid) se da de baja.
      if (existing && existing.uid !== uid) {
        await updateDoc(doc(clientsCollection(), existing.uid), { deletionDate: serverTimestamp() })
          .catch(() => warnings.push("No se pudo dar de baja su registro anterior de cliente; puede aparecer duplicado al buscar su correo."));
      }

      // 3. Pago del plan más la inscripción.
      let paymentResult: { id: string; approved: boolean } | null = null;
      try {
        paymentResult = await createPayment(uid, receptionistUid, plan.plan.cost + INSCRIPTION_FEE, payment);
      } catch (error) {
        console.error(error);
        warnings.push("El alumno quedó registrado, pero no se pudo registrar el pago. Regístralo de nuevo antes de darle acceso.");
      }

      // 4. Con el pago aprobado se crea la renovación y se marca la inscripción como pagada.
      let activated = false;
      if (paymentResult?.approved) {
        try {
          const start = new Date();
          const renewalRef = doc(memberDb, COLLECTIONS.members, uid, COLLECTIONS.renewals, crypto.randomUUID().replace(/-/g, ""));
          const batch = writeBatch(memberDb);
          batch.set(renewalRef, {
            uid: renewalRef.id,
            startDate: Timestamp.fromDate(start),
            endDate: Timestamp.fromDate(new Date(start.getTime() + DURATION_DAYS[plan.plan.duration] * DAY_MS)),
            membershipPlanRef: doc(memberDb, COLLECTIONS.membershipPlans, plan.id),
            paymentRef: doc(memberDb, COLLECTIONS.payments, paymentResult.id),
            amount: plan.plan.cost,
            creationDate: serverTimestamp(),
          });
          batch.update(doc(memberDb, COLLECTIONS.members, uid), { latestRenewalRef: renewalRef, inscriptionPaid: true });
          await batch.commit();
          activated = true;
        } catch (error) {
          console.error(error);
          warnings.push("El pago quedó registrado, pero no se pudo activar la membresía (renovación).");
        }
      }

      // 5. Correo para que el alumno elija su contraseña de la app.
      await sendPasswordResetEmail(auth, email)
        .catch(() => warnings.push("No se pudo enviar el correo para que el alumno elija su contraseña; puede usar «¿Olvidaste tu contraseña?» en la app."));

      return { uid, activated, warnings };
    } catch (error) {
      const message = registrationMessage(error);
      throw message ? new RegistrationError(message) : error;
    } finally {
      await signOut(memberAuth).catch(() => undefined);
      await deleteApp(secondary).catch(() => undefined);
    }
  },
};
