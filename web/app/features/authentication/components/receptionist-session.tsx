"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";

import type { Receptionist } from "../models/receptionist-model";
import { firebaseReceptionistRepository as repository } from "../repositories/firebase-receptionist-repository";

const ReceptionistContext = createContext<Receptionist | null>(null);

/** Perfil de `receptionists/{uid}` del recepcionista con sesión. Solo funciona dentro de <ReceptionistGate>. */
export function useReceptionist(): Receptionist {
  const receptionist = useContext(ReceptionistContext);
  if (!receptionist) throw new Error("useReceptionist debe usarse dentro de <ReceptionistGate>.");
  return receptionist;
}

/** Muestra la pantalla solo a un recepcionista activo; si no hay sesión, regresa al inicio de sesión. */
export function ReceptionistGate({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [receptionist, setReceptionist] = useState<Receptionist | null>(null);

  useEffect(() => repository.observeSession(
    (profile) => {
      setReceptionist(profile);
      if (!profile) router.replace("/");
    },
    () => router.replace("/"),
  ), [router]);

  if (!receptionist) return <p className="session-checking" role="status">Verificando sesión…</p>;
  return <ReceptionistContext.Provider value={receptionist}>{children}</ReceptionistContext.Provider>;
}
