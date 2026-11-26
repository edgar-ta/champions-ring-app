"use client";

// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";

import type { CoreReceptionist } from "@/src/core/models/core_receptionist";
import { firebaseReceptionistRepository as repository } from "../repositories/firebase-receptionist-repository";

const ReceptionistContext = createContext<CoreReceptionist | null>(null);

/** Perfil de `receptionists/{uid}` del recepcionista con sesión. Solo funciona dentro de <ReceptionistGate>. */
export function useReceptionist(): CoreReceptionist {
  const receptionist = useContext(ReceptionistContext);
  if (!receptionist) throw new Error("useReceptionist debe usarse dentro de <ReceptionistGate>.");
  return receptionist;
}

/** Muestra la pantalla solo a un recepcionista activo; si no hay sesión, regresa al inicio de sesión. */
export function ReceptionistGate({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [receptionist, setReceptionist] = useState<CoreReceptionist | null>(null);

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
