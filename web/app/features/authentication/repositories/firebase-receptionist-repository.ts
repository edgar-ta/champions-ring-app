import { FirebaseError } from "firebase/app";
import { browserLocalPersistence, browserSessionPersistence, onAuthStateChanged, setPersistence, signInWithEmailAndPassword, signOut } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/app/core/firebase/firebase";
import type { Receptionist } from "../models/receptionist-model";

async function getReceptionist(uid: string): Promise<Receptionist> {
  const snapshot = await getDoc(doc(db, "users", uid));
  const data = snapshot.data();
  if (!snapshot.exists() || data?.uid !== uid || data.type !== "receptionist" || data.deletion_date != null) {
    throw new Error("Esta cuenta no tiene acceso como recepcionista o fue dada de baja.");
  }
  return data as Receptionist;
}

export const firebaseReceptionistRepository = {
  async login(email: string, password: string, remember: boolean): Promise<Receptionist> {
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
  observeSession(onChange: (user: Receptionist | null) => void, onError: (error: unknown) => void) {
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
