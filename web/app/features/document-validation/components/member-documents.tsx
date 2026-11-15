"use client";

import { doc, Timestamp } from "firebase/firestore";
import { useState, type FormEvent } from "react";

import { COLLECTIONS } from "@/app/core/firebase/collections";
import { db } from "@/app/core/firebase/firebase";
import type { DocumentRejection, Member } from "@/app/core/models/member";
import { firestoreErrorMessage } from "@/app/core/utils/firebase-errors";
import { formatDate, toDate } from "@/app/core/utils/format";
import { useReceptionist } from "@/app/features/authentication/components/receptionist-session";
import { firebaseMemberDocumentsRepository as repository } from "../repositories/firebase-member-documents-repository";
import { REJECTION_FIELDS, type MemberDocumentField } from "../repositories/member-documents-repository";

export type MemberDocument = { field: MemberDocumentField; label: string; url: string | null; validated: boolean; rejection: DocumentRejection | null };

/** Datos del alumno para escribirle el aviso por correo. */
export type DocumentOwner = { name: string; email: string };

const COMMENT_LIMIT = 500;
const QUICK_REASONS = ["La foto está borrosa", "No se ve completo el documento", "El documento está vencido", "No corresponde al documento solicitado", "Los datos no coinciden con el alumno"];

/** Solo se abren enlaces https (las URLs de descarga de Firebase Storage). */
export function safeUrl(value: string | null | undefined): string | null {
  if (!value) return null;
  try { return new URL(value).protocol === "https:" ? value : null; } catch { return null; }
}

/** Documentos que se revisan en recepción. La CURP y la responsiva solo aparecen si el miembro las subió. */
export function documentsOf(member: Member): MemberDocument[] {
  // Para un menor (legalDataAreTheirs: false), la INE guardada es la de su tutor.
  const ine = member.legalDataAreTheirs === false ? "INE del tutor" : "INE";
  const entry = (field: MemberDocumentField, label: string, url: string | null | undefined): MemberDocument => {
    const validated = member[field] === true;
    return { field, label, url: safeUrl(url), validated, rejection: validated ? null : member[REJECTION_FIELDS[field]] ?? null };
  };
  const documents = [entry("ineFrontValidated", `${ine} (frente)`, member.ineFrontUrl), entry("ineBackValidated", `${ine} (reverso)`, member.ineBackUrl)];
  if (member.curpUrl) documents.push(entry("curpValidated", "CURP", member.curpUrl));
  if (member.waiverAgreementUrl) documents.push(entry("waiverAgreementValidated", "Carta responsiva", member.waiverAgreementUrl));
  return documents;
}

/** Correo ya redactado para avisarle al alumno qué debe corregir (se abre en el correo de la recepcionista). */
export function rejectionMailto(owner: DocumentOwner, label: string, comment: string, signature: string): string {
  const subject = `Champions Ring: corrige tu ${label}`;
  const body = [
    `Hola ${owner.name}:`,
    "",
    `Revisamos tus documentos en Champions Ring y tu ${label} no se pudo validar.`,
    "",
    `Qué hay que corregir: ${comment}`,
    "",
    "Por favor vuelve a subirlo desde la app de Champions Ring. Si tienes dudas, acércate a recepción.",
    "",
    "Gracias,",
    signature,
    "Recepción · Champions Ring",
  ].join("\n");
  return `mailto:${encodeURIComponent(owner.email)}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
}

const ICONS: Record<MemberDocumentField, string> = {
  ineFrontValidated: "M3 5h18v14H3ZM7 10a2 2 0 1 0 4 0 2 2 0 0 0-4 0M5.5 16c.6-1.6 1.9-2.5 3.5-2.5s2.9.9 3.5 2.5M14 9h5M14 12h5M14 15h3",
  ineBackValidated: "M3 5h18v14H3ZM6 9h12M6 12h12M6 15h7",
  curpValidated: "M6 3h9l4 4v14H6ZM14 3v5h5M9 12h7M9 15h7M9 18h4",
  waiverAgreementValidated: "M6 3h9l4 4v14H6ZM14 3v5h5M8.5 17c1.5-2 2.5-2 3 0s1.5 1 2.5-.5",
};

/** Barra con el avance de validación: «2 de 4 validados · 1 rechazado». */
export function DocumentProgress({ documents }: { documents: MemberDocument[] }) {
  const done = documents.filter(document => document.validated).length;
  const rejected = documents.filter(document => document.rejection).length;
  const percent = documents.length ? Math.round((done / documents.length) * 100) : 0;
  const text = done === documents.length ? "Todos los documentos validados"
    : `${done} de ${documents.length} validados${rejected ? ` · ${rejected} ${rejected === 1 ? "rechazado" : "rechazados"}` : ""}`;
  return <div className={`doc-progress ${done === documents.length ? "complete" : ""}`}>
    <div className="doc-progress-text"><span>{text}</span><strong>{percent}%</strong></div>
    <div className="doc-progress-bar" role="progressbar" aria-valuemin={0} aria-valuemax={documents.length} aria-valuenow={done} aria-label="Documentos validados"><span style={{ width: `${percent}%` }}/></div>
  </div>;
}

/** Formulario para rechazar un documento con el comentario de qué corregir. */
function RejectForm({ document, owner, busy, onCancel, onSubmit }: {
  document: MemberDocument;
  owner: DocumentOwner;
  busy: boolean;
  onCancel: () => void;
  onSubmit: (comment: string, notifyByEmail: boolean) => void;
}) {
  const [comment, setComment] = useState(document.rejection?.comment ?? "");
  const [notify, setNotify] = useState(owner.email !== "");
  const id = `reject-${document.field}`;

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (comment.trim()) onSubmit(comment.trim(), notify);
  }

  return <form className="doc-reject-form" onSubmit={submit}>
    <label htmlFor={id}>¿Qué debe corregir el alumno en su {document.label}?</label>
    <div className="doc-reasons" role="group" aria-label="Motivos frecuentes">
      {QUICK_REASONS.map(reason => <button key={reason} type="button" disabled={busy} className={comment === reason ? "selected" : ""} onClick={() => setComment(reason)}>{reason}</button>)}
    </div>
    <textarea id={id} rows={3} required maxLength={COMMENT_LIMIT} value={comment} disabled={busy} autoFocus placeholder="Ej.: La foto salió con reflejo y no se leen los datos. Tómala de nuevo con buena luz." onChange={event => setComment(event.target.value)}/>
    <div className="doc-reject-meta">
      <label className="doc-reject-notify"><input type="checkbox" checked={notify} disabled={busy || !owner.email} onChange={event => setNotify(event.target.checked)}/>{owner.email ? <>Abrir mi correo para avisarle a <strong>{owner.email}</strong></> : "El alumno no tiene correo registrado"}</label>
      <small>{comment.length}/{COMMENT_LIMIT}</small>
    </div>
    <p className="doc-reject-hint">El comentario se guarda en su perfil para que lo vea en la app y vuelva a subir el documento.</p>
    <div className="doc-reject-actions">
      <button type="button" className="doc-view" onClick={onCancel} disabled={busy}>Cancelar</button>
      <button type="submit" className="doc-reject-confirm" disabled={busy || !comment.trim()}>{busy ? "Guardando…" : "Rechazar documento"}</button>
    </div>
  </form>;
}

/**
 * Lista de documentos de un miembro con «Ver», «Validar» y «Rechazar».
 * Se usa en la sección Documentos y en el perfil del alumno.
 * `onUpdated` recibe los campos que cambiaron, para actualizar la pantalla sin volver a consultar.
 */
const NO_OWNER: DocumentOwner = { name: "", email: "" };

export function MemberDocumentChecklist({ member, owner = NO_OWNER, onUpdated }: { member: Member; owner?: DocumentOwner; onUpdated?: (patch: Partial<Member>) => void }) {
  const receptionist = useReceptionist();
  const [saving, setSaving] = useState<MemberDocumentField | null>(null);
  const [rejecting, setRejecting] = useState<MemberDocumentField | null>(null);
  const [error, setError] = useState("");
  const signature = `${receptionist.name} ${receptionist.lastName}`.trim();

  async function validate(field: MemberDocumentField) {
    setSaving(field); setError("");
    try {
      await repository.validate(member.uid, field);
      onUpdated?.({ [field]: true, [REJECTION_FIELDS[field]]: null });
      if (rejecting === field) setRejecting(null);
    } catch (exception) { console.error(exception); setError(firestoreErrorMessage(exception, "validar el documento")); }
    finally { setSaving(null); }
  }

  async function reject(document: MemberDocument, comment: string, notifyByEmail: boolean) {
    setSaving(document.field); setError("");
    try {
      await repository.reject(member.uid, document.field, comment, receptionist.uid);
      const rejection: DocumentRejection = { comment, date: Timestamp.now(), receptionistRef: doc(db, COLLECTIONS.receptionists, receptionist.uid) };
      onUpdated?.({ [document.field]: false, [REJECTION_FIELDS[document.field]]: rejection });
      setRejecting(null);
      if (notifyByEmail && owner.email) window.location.assign(rejectionMailto(owner, document.label, comment, signature));
    } catch (exception) { console.error(exception); setError(firestoreErrorMessage(exception, "rechazar el documento")); }
    finally { setSaving(null); }
  }

  return <>
    {error && <p className="visitors-result error" role="alert">{error}</p>}
    <ul className="doc-checklist">
      {documentsOf(member).map(document => {
        const state = document.validated ? "validated" : document.rejection ? "rejected" : "";
        const rejectedOn = toDate(document.rejection?.date);
        const busy = saving !== null;
        return <li key={document.field} className={state}>
          <span className="doc-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d={ICONS[document.field]}/></svg></span>
          <span className="doc-label">
            <strong>{document.label}</strong>
            <small>{document.validated ? "Validado" : document.rejection ? `Rechazado${rejectedOn ? ` el ${formatDate(rejectedOn)}` : ""} · esperando que lo vuelva a subir` : document.url ? "Pendiente de revisar" : "Sin archivo"}</small>
          </span>
          <span className="doc-actions">
            {document.url ? <a className="doc-view" href={document.url} target="_blank" rel="noopener noreferrer">Ver<span className="sr-only"> {document.label}</span></a> : <span className="doc-missing">—</span>}
            {rejecting !== document.field && <button type="button" className="doc-reject" disabled={busy} onClick={() => { setError(""); setRejecting(document.field); }}>{document.rejection ? "Editar motivo" : "Rechazar"}</button>}
            {document.validated
              ? <span className="doc-badge"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" aria-hidden="true"><path d="m5 12 4.5 4.5L19 7"/></svg>Validado</span>
              : <button type="button" className="doc-validate" disabled={!document.url || busy} onClick={() => validate(document.field)}>{saving === document.field && rejecting !== document.field ? "Validando…" : "Validar"}</button>}
          </span>

          {document.rejection && rejecting !== document.field && <div className="doc-rejection">
            <p><strong>Motivo enviado al alumno:</strong> {document.rejection.comment}</p>
            {owner.email && <a href={rejectionMailto(owner, document.label, document.rejection.comment, signature)}>Volver a avisar por correo</a>}
          </div>}

          {rejecting === document.field && <RejectForm document={document} owner={owner} busy={saving === document.field} onCancel={() => setRejecting(null)} onSubmit={(comment, notify) => reject(document, comment, notify)}/>}
        </li>;
      })}
    </ul>
  </>;
}

