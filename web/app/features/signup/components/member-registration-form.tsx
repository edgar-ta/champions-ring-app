"use client";

import { useEffect, useMemo, useRef, useState, type FormEvent } from "react";

import { INSCRIPTION_FEE } from "@/app/core/constants/membership";
import type { Client } from "@/app/core/models/client";
import { formatCurrency } from "@/app/core/utils/format";
import { isMinor, type MemberRecord, type PaymentDetails, type PersonalData, type PlanOption, type WaiverSignature } from "../models/registration";
import { DOCUMENT_LABELS, IMAGE_TYPES, imageError, type DocumentField } from "../services/file-validation";
import { WAIVER_PARAGRAPHS, WAIVER_TITLE } from "../services/waiver-pdf";
import { PaymentLines, PaymentMethodFields, paymentFromForm } from "./payment-step";
import { SignaturePad, type SignaturePadHandle } from "./signature-pad";

export interface MemberRegistration {
  personal: PersonalData;
  record: MemberRecord;
  waiver: WaiverSignature;
  plan: PlanOption;
  payment: PaymentDetails;
}

const PLAN_TITLES: Record<string, string> = { "1w": "Semana", "1m": "Mes" };
const toInputDate = (date: Date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;

/**
 * Registro completo de un alumno (Semana o Mes), con los datos del paso 1 ya llenos:
 * datos, flujo de menores, foto y documentos, membresía, pago y responsiva firmada.
 */
export function MemberRegistrationForm({ personal, existing, plans, initialPlan, busy, error, onBack, onSubmit }: {
  personal: PersonalData;
  existing: Client | null;
  /** Solo planes Semana y Mes. */
  plans: PlanOption[];
  initialPlan: PlanOption;
  busy: boolean;
  error: string;
  onBack: () => void;
  onSubmit: (registration: MemberRegistration) => void;
}) {
  const [planId, setPlanId] = useState(initialPlan.id);
  const [birthDate, setBirthDate] = useState("");
  const [files, setFiles] = useState<Partial<Record<DocumentField, File>>>({});
  const [signed, setSigned] = useState(false);
  const [accepted, setAccepted] = useState(false);
  const [formError, setFormError] = useState("");
  const pad = useRef<SignaturePadHandle>(null);

  // La vista previa de la foto usa una URL temporal que se libera al cambiarla o al salir.
  const photoPreview = useMemo(() => (files.photo ? URL.createObjectURL(files.photo) : null), [files.photo]);
  useEffect(() => () => { if (photoPreview) URL.revokeObjectURL(photoPreview); }, [photoPreview]);

  const plan = plans.find(option => option.id === planId) ?? initialPlan;
  const parsedBirthDate = birthDate ? new Date(`${birthDate}T12:00:00`) : null;
  const minor = parsedBirthDate ? isMinor(parsedBirthDate) : false;
  // Si ya era cliente (prospecto o visita), se muestran sus datos guardados.
  const name = existing?.name ?? personal.name;
  const lastName = existing?.lastName ?? personal.lastName;

  // Si el alumno es menor, la INE que se sube es la de su tutor (se guarda en ineFrontUrl / ineBackUrl).
  const labelOf = (field: DocumentField) =>
    minor && (field === "ineFront" || field === "ineBack") ? `INE del tutor (${field === "ineFront" ? "frente" : "reverso"})` : DOCUMENT_LABELS[field];

  function pick(field: DocumentField, file: File | undefined) {
    setFormError("");
    if (!file) return;
    const problem = imageError(field, file);
    if (problem) { setFormError(problem); return; }
    setFiles(current => ({ ...current, [field]: file }));
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    const data = new FormData(event.currentTarget);
    if (!parsedBirthDate || parsedBirthDate > new Date()) { setFormError("Escribe una fecha de nacimiento válida."); return; }
    const required: DocumentField[] = ["photo", "ineFront", "ineBack", ...(minor ? ["curp" as const] : [])];
    const missing = required.filter(field => !files[field]);
    if (missing.length) { setFormError(`Falta subir: ${missing.map(field => labelOf(field)).join(", ")}.`); return; }
    const signatureDataUrl = pad.current?.toDataUrl();
    if (!signatureDataUrl) { setFormError(`Falta la firma de la responsiva${minor ? " del tutor" : ""}.`); return; }
    if (!accepted) { setFormError("Hay que aceptar los términos y condiciones de la responsiva."); return; }
    setFormError("");
    onSubmit({
      personal: { name: String(data.get("name")).trim(), lastName: String(data.get("lastName")).trim(), email: personal.email },
      record: {
        birthDate: parsedBirthDate,
        phone: String(data.get("phone")).trim(),
        photo: files.photo!,
        ineFront: files.ineFront!,
        ineBack: files.ineBack!,
        curp: minor ? files.curp ?? null : null,
        guardianName: minor ? String(data.get("guardianName")).trim() : null,
        guardianPhone: minor ? String(data.get("guardianPhone")).trim() : null,
        guardianRelationship: minor ? String(data.get("guardianRelationship")).trim() : null,
      },
      waiver: { signatureDataUrl, signedAt: new Date() },
      plan,
      payment: paymentFromForm(data),
    });
  }

  const fileChip = (field: DocumentField, disabled = false) => <label className={`member-file ${files[field] ? "chosen" : ""} ${disabled ? "disabled" : ""}`}>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M4 3h11l5 5v13H4ZM14 3v6h6"/></svg>
    <span>{files[field]?.name ?? `Subir ${labelOf(field)}`}</span>
    <input type="file" accept={IMAGE_TYPES.join(",")} disabled={disabled || busy} onChange={event => pick(field, event.target.files?.[0])}/>
  </label>;

  return <form className="member-form" onSubmit={submit} aria-busy={busy}>
    <section className="settings-panel member-form-main">
      <h2>Datos del alumno</h2>
      <div className="settings-fields">
        <div className="settings-field half"><label htmlFor="member-name">Nombre(s)<span> *</span></label><input id="member-name" name="name" required maxLength={80} defaultValue={name} disabled={busy}/></div>
        <div className="settings-field half"><label htmlFor="member-last-name">Apellidos<span> *</span></label><input id="member-last-name" name="lastName" required maxLength={120} defaultValue={lastName} disabled={busy}/></div>
        <div className="settings-field half"><label htmlFor="member-birth-date">Fecha de nacimiento<span> *</span></label><input id="member-birth-date" type="date" required max={toInputDate(new Date())} value={birthDate} onChange={event => setBirthDate(event.target.value)} disabled={busy}/></div>
        <div className="settings-field half"><label htmlFor="member-phone">Teléfono (10 dígitos)<span> *</span></label><input id="member-phone" name="phone" type="tel" inputMode="numeric" required pattern="[0-9]{10}" maxLength={10} placeholder="5512345678" disabled={busy}/></div>
        <div className="settings-field"><label htmlFor="member-email">Correo electrónico</label><input id="member-email" type="email" value={personal.email} readOnly/></div>
      </div>
      <fieldset className={`minor-flow ${minor ? "active" : ""}`} disabled={!minor || busy}>
        <legend>Flujo para Menores de Edad</legend>
        <p>{minor ? "El alumno es menor de edad: ingresa los datos de su padre, madre o tutor y sube la INE del tutor. El tutor firma la responsiva." : "Se activa si la fecha de nacimiento corresponde a un menor de edad."}</p>
        <div className="settings-fields">
          <div className="settings-field half"><label htmlFor="member-guardian-name">Nombre del tutor<span> *</span></label><input id="member-guardian-name" name="guardianName" required={minor} maxLength={120}/></div>
          <div className="settings-field half"><label htmlFor="member-guardian-phone">Teléfono del tutor<span> *</span></label><input id="member-guardian-phone" name="guardianPhone" type="tel" inputMode="numeric" required={minor} pattern="[0-9]{10}" maxLength={10}/></div>
          <div className="settings-field half"><span className="visitors-label">CURP del menor<span className="required-mark"> *</span></span>{fileChip("curp", !minor)}</div>
          <div className="settings-field half"><label htmlFor="member-guardian-relationship">Parentesco<span> *</span></label><input id="member-guardian-relationship" name="guardianRelationship" required={minor} maxLength={40} placeholder="Madre / Padre"/></div>
          <div className="settings-field"><span className="visitors-label">INE del tutor<span className="required-mark"> *</span></span><div className="member-files member-files-row">{fileChip("ineFront", !minor)}{fileChip("ineBack", !minor)}</div></div>
        </div>
      </fieldset>
    </section>

    <div className="member-form-side">
      <section className="settings-panel">
        <h2>Fotografía y Documentos</h2>
        <div className="member-photo">
          {/* eslint-disable-next-line @next/next/no-img-element -- vista previa local (blob:) */}
          {photoPreview ? <img src={photoPreview} alt="Vista previa de la foto del alumno"/> : <span aria-hidden="true"/>}
          <div>
            <label className="settings-outline member-photo-button">Cargar foto de alumno<input type="file" accept={IMAGE_TYPES.join(",")} capture="user" disabled={busy} onChange={event => pick("photo", event.target.files?.[0])}/></label>
            <small>Formatos aceptados: JPG, PNG, WEBP</small>
          </div>
        </div>
        <span className="visitors-label">Validación de Identidad (INE)</span>
        {minor
          ? <p className="member-ine-note">El alumno es menor de edad: la INE la sube su tutor en el apartado «Flujo para Menores de Edad».</p>
          : <div className="member-files">{fileChip("ineFront")}{fileChip("ineBack")}</div>}
      </section>

      <section className="settings-panel">
        <h2>Selección de Membresía</h2>
        <div className="member-plans" role="radiogroup" aria-label="Plan">
          {plans.map(option => <label key={option.id} className={option.id === planId ? "selected" : ""}>
            <input type="radio" name="plan" value={option.id} checked={option.id === planId} onChange={() => setPlanId(option.id)} disabled={busy}/>
            {PLAN_TITLES[option.plan.duration]} ({formatCurrency(option.plan.cost)})
          </label>)}
        </div>
        <PaymentLines lines={[{ label: `Plan ${PLAN_TITLES[plan.plan.duration]}`, amount: plan.plan.cost }, { label: "Inscripción", amount: INSCRIPTION_FEE }]}/>
        <div className="settings-fields member-payment"><PaymentMethodFields initial={null} disabled={busy}/></div>

        <details className="member-waiver">
          <summary>Ver carta responsiva</summary>
          <h3>{WAIVER_TITLE}</h3>
          {WAIVER_PARAGRAPHS.map(paragraph => <p key={paragraph}>{paragraph}</p>)}
        </details>
        <span className="visitors-label">Firma {minor ? "del padre, madre o tutor" : "del alumno"}</span>
        <SignaturePad ref={pad} onChange={setSigned} label="Área de firma de la responsiva"/>
        <button type="button" className="member-clear-signature" onClick={() => pad.current?.clear()} disabled={!signed || busy}>Borrar firma</button>
        <label className="waiver-accept"><input type="checkbox" checked={accepted} onChange={event => setAccepted(event.target.checked)} disabled={busy}/>Acepto los términos y condiciones de la responsiva médica.</label>

        {(formError || error) && <p className="visitors-result error" role="alert">{formError || error}</p>}
        <button type="submit" className="settings-save member-submit" disabled={busy}>{busy ? "Registrando…" : "Finalizar registro"}</button>
        <button type="button" className="member-back" onClick={onBack} disabled={busy}>← Cambiar tipo de registro</button>
      </section>
    </div>
  </form>;
}
