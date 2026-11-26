"use client";

import { useState, type FormEvent } from "react";

import { firestoreErrorMessage } from "@/src/core/utils/firebase-errors";
import type { EmailLookup, PersonalData } from "../models/registration";
import { firebaseRegistrationRepository as repository } from "../repositories/firebase-registration-repository";

/**
 * Paso 1: nombre, apellidos y correo. Al continuar se busca el correo para saber si la persona
 * ya es alumno (no se puede registrar otra vez) o ya es cliente (prospecto o visita).
 */
export function PersonalStep({ initial, onNext }: { initial: PersonalData | null; onNext: (personal: PersonalData, lookup: EmailLookup) => void }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    const data = new FormData(event.currentTarget);
    const personal = { name: String(data.get("name")).trim(), lastName: String(data.get("lastName")).trim(), email: String(data.get("email")).trim() };
    setBusy(true); setError("");
    try {
      const lookup = await repository.lookupEmail(personal.email);
      if (lookup.isMember) {
        setError(`${lookup.client?.name ?? ""} ${lookup.client?.lastName ?? ""}`.trim() + " ya es alumno de Champions Ring con este correo. Búscalo en la lista de Alumnos.");
        return;
      }
      onNext(personal, lookup);
    } catch (exception) {
      console.error(exception);
      setError(firestoreErrorMessage(exception, "verificar el correo"));
    } finally { setBusy(false); }
  }

  return <form className="settings-fields" onSubmit={submit} aria-busy={busy}>
    <div className="settings-field half"><label htmlFor="signup-name">Nombre(s)<span> *</span></label><input id="signup-name" name="name" defaultValue={initial?.name} required maxLength={80} autoComplete="off" disabled={busy}/></div>
    <div className="settings-field half"><label htmlFor="signup-last-name">Apellidos<span> *</span></label><input id="signup-last-name" name="lastName" defaultValue={initial?.lastName} required maxLength={120} autoComplete="off" disabled={busy}/></div>
    <div className="settings-field"><label htmlFor="signup-email">Correo electrónico<span> *</span></label><input id="signup-email" name="email" type="email" defaultValue={initial?.email} required maxLength={254} autoComplete="off" disabled={busy}/></div>
    {error && <p className="visitors-result error wizard-full" role="alert">{error}</p>}
    <div className="visitors-actions"><button className="settings-save" type="submit" disabled={busy}>{busy ? "Verificando…" : "Continuar"}</button></div>
  </form>;
}
