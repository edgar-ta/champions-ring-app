import { FirebaseError } from "firebase/app";
import { browserLocalPersistence, browserSessionPersistence, onAuthStateChanged, sendPasswordResetEmail, setPersistence, signInWithEmailAndPassword, signOut } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/app/core/firebase/firebase";
import { COLLECTIONS } from "@/app/core/firebase/collections";
import type { Receptionist } from "../models/receptionist-model";
import type { ReceptionistRepository } from "./receptionist-repository";

// Una cuenta es recepcionista si existe receptionists/{uid} y no fue dada de baja
// (Modelo de Datos en Firebase v20.0.0).
async function getReceptionist(uid: string): Promise<Receptionist> {
  const snapshot = await getDoc(doc(db, COLLECTIONS.receptionists, uid));
  const data = snapshot.data();
  if (!snapshot.exists() || data?.uid !== uid || data.deletionDate != null) {
    throw new Error("Esta cuenta no tiene acceso como recepcionista o fue dada de baja.");
  }
  return data as Receptionist;
}

export const firebaseReceptionistRepository: ReceptionistRepository = {
  async login(email, password, remember) {
    await setPersistence(auth, remember ? browserLocalPersistence : browserSessionPersistence);
    const credential = await signInWithEmailAndPassword(auth, email.trim(), password);
    try {
      return await getReceptionist(credential.user.uid);
    } catch (error) {
      await signOut(auth);
      throw error;
    }
  },
  logout: () => signOut(auth),
  async sendPasswordReset(email) {
    // El correo de Firebase llega en español.
    auth.languageCode = "es";
    await sendPasswordResetEmail(auth, email.trim());
  },
  observeSession(onChange, onError) {
    let revision = 0;
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      const current = ++revision;
      if (!user) { onChange(null); return; }
      try {
        const profile = await getReceptionist(user.uid);
        if (current === revision) onChange(profile);
      } catch (error) {
        if (current !== revision) return;
        onChange(null);
        onError(error);
        try { await signOut(auth); } catch (logoutError) { onError(logoutError); }
      }
    }, onError);
    return () => { revision++; unsubscribe(); };
  },
};

export function passwordResetErrorMessage(error: unknown): string {
  if (error instanceof FirebaseError) {
    switch (error.code) {
      case "auth/invalid-email":
      case "auth/missing-email": return "Ingresa un correo electrónico válido.";
      // Por seguridad no se dice si el correo existe: se responde como si se hubiera enviado.
      case "auth/user-not-found": return "";
      case "auth/too-many-requests": return "Se enviaron demasiadas solicitudes. Espera unos minutos e inténtalo de nuevo.";
      case "auth/network-request-failed": return "No se pudo conectar. Revisa tu conexión.";
    }
  }
  return "No se pudo enviar el correo. Inténtalo de nuevo.";
}

export function loginErrorMessage(error: unknown): string {
  if (error instanceof FirebaseError) {
    switch (error.code) {
      case "auth/invalid-credential":
      case "auth/wrong-password":
      case "auth/user-not-found": return "Correo o contraseña incorrectos.";
      case "auth/invalid-email": return "Ingresa un correo electrónico válido.";
      case "auth/user-disabled": return "Esta cuenta está deshabilitada.";
      case "auth/too-many-requests": return "Demasiados intentos. Inténtalo más tarde.";
      case "auth/network-request-failed": return "No se pudo conectar. Revisa tu conexión.";
      case "permission-denied": return "No tienes permiso para consultar tu perfil. Contacta al administrador.";
      default: return "No se pudo iniciar sesión. Inténtalo de nuevo.";
    }
  }
  return error instanceof Error ? error.message : "No se pudo iniciar sesión. Inténtalo de nuevo.";
}
