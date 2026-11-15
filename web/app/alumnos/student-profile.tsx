"use client";

import { useState, type ReactNode } from "react";

import { INSCRIPTION_FEE } from "@/app/core/constants/membership";
import { PAYMENT_TYPE_LABELS } from "@/app/core/models/payment";
import { formatCurrency, formatDate, formatTime, initials } from "@/app/core/utils/format";
import { DocumentProgress, MemberDocumentChecklist, documentsOf, safeUrl } from "@/app/features/document-validation/components/member-documents";
import type { Member } from "@/app/core/models/member";
import { STATUS_LABELS, type MemberSummary } from "@/app/features/members/models/member-summary";
import { VISITOR_LABELS, type VisitorKind, type VisitorSummary } from "@/app/features/members/models/visitor-summary";

/** Una fila de la tabla: un alumno con membresía, o una persona que vino de visita o a su clase muestra. */
export type Row =
  | { kind: "member"; uid: string; fullName: string; email: string; sortDate: number; member: MemberSummary }
  | { kind: VisitorKind; uid: string; fullName: string; email: string; sortDate: number; visitor: VisitorSummary };

const tones = ["sage", "sand", "blue", "slate", "rose"];
const DAY = 24 * 60 * 60 * 1000;

export const formatDateTime = (date: Date) => `${formatDate(date)}, ${formatTime(date)}`;
export const isMinor = (row: Row) => row.kind === "member" && row.member.age !== null && row.member.age < 18;

export function Avatar({ row, large = false }: { row: Row; large?: boolean }) {
  const photo = row.kind === "member" ? safeUrl(row.member.photoUrl) : null;
  const size = large ? " profile-avatar" : "";
  // eslint-disable-next-line @next/next/no-img-element -- fotos de Firebase Storage con dominio variable
  if (photo) return <img className={`student-avatar student-photo${size}`} src={photo} alt={large ? `Foto de ${row.fullName}` : ""}/>;
  const tone = tones[[...row.uid].reduce((sum, char) => sum + char.charCodeAt(0), 0) % tones.length];
  return <span className={`student-avatar ${tone}${size}`} aria-hidden="true">{initials(row.fullName)}</span>;
}

const ICON_PATHS = {
  mail: "M3 6h18v12H3ZM3 7l9 6 9-6",
  phone: "M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2",
  cake: "M4 21h16v-8H4ZM4 16c2 1.5 4 1.5 6 0s4-1.5 6 0 3 1 4 0M12 13V9M12 6a1.5 1.5 0 0 0 1.5-1.5C13.5 3.5 12 2 12 2s-1.5 1.5-1.5 2.5A1.5 1.5 0 0 0 12 6",
  calendar: "M4 5h16v16H4ZM4 10h16M8 3v4M16 3v4",
  user: "M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8",
  heart: "M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10",
  star: "m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9Z",
};

function Info({ icon, label, children }: { icon: keyof typeof ICON_PATHS; label: string; children: ReactNode }) {
  return <div className="profile-info-item">
    <span className="profile-info-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d={ICON_PATHS[icon]}/></svg></span>
    <div><dt>{label}</dt><dd>{children}</dd></div>
  </div>;
}

function Stat({ label, value, hint, tone }: { label: string; value: string; hint?: string; tone?: "good" | "warn" | "bad" }) {
  return <div className={`profile-stat ${tone ?? ""}`}><span>{label}</span><strong>{value}</strong>{hint && <small>{hint}</small>}</div>;
}

function MemberProfile({ row, onUpdated }: { row: Extract<Row, { kind: "member" }>; onUpdated: (patch: Partial<Member>) => void }) {
  const { member } = row;
  const record = member.record;
  const documents = documentsOf(record);
  // La hora se toma una vez al abrir el perfil.
  const [now] = useState(() => Date.now());
  const daysLeft = member.membershipEnd ? Math.ceil((member.membershipEnd.getTime() - now) / DAY) : null;
  const statusTone = member.status === "active" ? "good" : member.status === "expiring" ? "warn" : member.status === "expired" ? "bad" : undefined;
  const minor = isMinor(row);

  return <>
    <div className="profile-stats">
      <Stat label="Membresía" value={member.planLabel ?? "—"} hint={STATUS_LABELS[member.status]} tone={statusTone}/>
      <Stat label={daysLeft !== null && daysLeft < 0 ? "Venció hace" : "Días restantes"} value={daysLeft === null ? "—" : `${Math.abs(daysLeft)}`} hint={member.membershipEnd ? `${daysLeft !== null && daysLeft < 0 ? "Venció" : "Vence"} el ${formatDate(member.membershipEnd)}` : "Sin renovación"} tone={statusTone}/>
      <Stat label="Inscripción" value={member.inscriptionPaid ? "Pagada" : "Pendiente"} hint={`Cuota de ${formatCurrency(INSCRIPTION_FEE)}`} tone={member.inscriptionPaid ? "good" : "warn"}/>
    </div>

    <section className="profile-section" aria-labelledby="profile-personal-title">
      <h3 id="profile-personal-title">Datos personales</h3>
      <dl className="profile-info">
        <Info icon="mail" label="Correo">{member.email || "—"}</Info>
        <Info icon="phone" label="Teléfono">{member.phone ? <a href={`tel:${member.phone}`}>{member.phone}</a> : "—"}</Info>
        <Info icon="cake" label="Edad">{member.age !== null ? `${member.age} años` : "—"}</Info>
        <Info icon="calendar" label="Registro">{member.creationDate ? formatDate(member.creationDate) : "—"}</Info>
      </dl>
    </section>

    {(minor || record.guardianName) && <section className="profile-section" aria-labelledby="profile-guardian-title">
      <h3 id="profile-guardian-title">Padre, madre o tutor</h3>
      <dl className="profile-info">
        <Info icon="user" label="Nombre">{record.guardianName || "—"}</Info>
        <Info icon="phone" label="Teléfono">{record.guardianPhone ? <a href={`tel:${record.guardianPhone}`}>{record.guardianPhone}</a> : "—"}</Info>
        <Info icon="heart" label="Parentesco">{record.guardianRelationship || "—"}</Info>
      </dl>
    </section>}

    <section className="profile-section" aria-labelledby="profile-documents-title">
      <h3 id="profile-documents-title">Documentos</h3>
      <DocumentProgress documents={documents}/>
      <MemberDocumentChecklist member={record} owner={{ name: row.fullName.split(" ")[0] || row.fullName, email: member.email }} onUpdated={onUpdated}/>
    </section>
  </>;
}

function VisitorProfile({ row }: { row: Extract<Row, { kind: VisitorKind }> }) {
  const { visitor } = row;
  const paid = visitor.visits.reduce((sum, visit) => sum + visit.amount, 0);
  return <>
    <div className="profile-stats">
      <Stat label="Visitas" value={String(visitor.visits.length)} hint={visitor.lastDate ? `Última: ${formatDate(visitor.lastDate)}` : "Ninguna"}/>
      <Stat label="Total pagado" value={formatCurrency(paid)} hint="En visitas"/>
      <Stat label="Clase muestra" value={visitor.sampleClassDate ? "Tomada" : "No"} hint={visitor.sampleClassDate ? formatDate(visitor.sampleClassDate) : "Disponible"} tone={visitor.sampleClassDate ? undefined : "good"}/>
    </div>

    <section className="profile-section" aria-labelledby="profile-personal-title">
      <h3 id="profile-personal-title">Datos</h3>
      <dl className="profile-info">
        <Info icon="mail" label="Correo">{visitor.email || "—"}</Info>
        <Info icon="star" label="Tipo">{VISITOR_LABELS[row.kind]}</Info>
        <Info icon="calendar" label="Registro">{visitor.creationDate ? formatDateTime(visitor.creationDate) : "—"}</Info>
        <Info icon="user" label="Clase muestra">{visitor.sampleClassDate ? formatDateTime(visitor.sampleClassDate) : "No la tomó"}</Info>
      </dl>
    </section>

    {visitor.visits.length > 0 && <section className="profile-section" aria-labelledby="profile-visits-title">
      <h3 id="profile-visits-title">Historial de visitas</h3>
      <ol className="profile-timeline">{visitor.visits.map(visit => <li key={visit.paymentUid}>
        <time dateTime={visit.date.toISOString()}>{formatDateTime(visit.date)}</time>
        <span>{formatCurrency(visit.amount)} · {PAYMENT_TYPE_LABELS[visit.type] ?? visit.type}</span>
        {visit.pending && <em>Pendiente de confirmar</em>}
      </li>)}</ol>
    </section>}
  </>;
}

/** Contenido del diálogo «Ver perfil»: encabezado con foto y estado, resumen, datos y documentos. */
export function StudentProfile({ row, onClose, onUpdated }: { row: Row; onClose: () => void; onUpdated: (patch: Partial<Member>) => void }) {
  const eyebrow = row.kind === "member" ? "Perfil del alumno" : row.kind === "visit" ? "Perfil del visitante" : "Perfil del prospecto";
  const status = row.kind === "member"
    ? { label: STATUS_LABELS[row.member.status], className: row.member.status }
    : { label: VISITOR_LABELS[row.kind], className: row.kind };
  const photo = row.kind === "member" ? safeUrl(row.member.photoUrl) : null;
  const rejectedDocuments = row.kind === "member" ? documentsOf(row.member.record).filter(document => document.rejection).length : 0;
  const pendingDocuments = row.kind === "member" && !row.member.documentsValidated && rejectedDocuments === 0;

  return <>
    <header className={`profile-hero ${row.kind === "member" ? row.member.status : row.kind}`}>
      <button type="button" className="profile-close" onClick={onClose} aria-label="Cerrar perfil"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18"/></svg></button>
      {photo ? <a href={photo} target="_blank" rel="noopener noreferrer" className="profile-avatar-link" title="Ver foto completa"><Avatar row={row} large/></a> : <Avatar row={row} large/>}
      <div className="profile-hero-text">
        <p>{eyebrow}</p>
        <h2 id="student-profile-title">{row.fullName}</h2>
        <div className="profile-chips">
          <span className={`student-status ${status.className}`}>{status.label}</span>
          {isMinor(row) && <span className="profile-chip">Menor de edad</span>}
          {pendingDocuments && <span className="profile-chip warn">Documentos pendientes</span>}
          {rejectedDocuments > 0 && <span className="profile-chip bad">{rejectedDocuments === 1 ? "1 documento rechazado" : `${rejectedDocuments} documentos rechazados`}</span>}
          {row.kind === "member" && row.member.documentsValidated && <span className="profile-chip good">Documentos validados</span>}
        </div>
      </div>
    </header>
    <div className="profile-body">
      {row.kind === "member" ? <MemberProfile row={row} onUpdated={onUpdated}/> : <VisitorProfile row={row}/>}
    </div>
    <footer className="profile-footer"><button className="settings-save" type="button" onClick={onClose}>Cerrar</button></footer>
  </>;
}
