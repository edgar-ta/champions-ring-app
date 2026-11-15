"use client";

import { useEffect, useState } from "react";

import { firestoreErrorMessage } from "@/app/core/utils/firebase-errors";
import { ageOn, formatDate, initials, toDate } from "@/app/core/utils/format";
import { firebaseMemberDocumentsRepository as repository } from "../repositories/firebase-member-documents-repository";
import type { PendingMember } from "../repositories/member-documents-repository";
import { DocumentProgress, MemberDocumentChecklist, documentsOf, safeUrl } from "./member-documents";

type ListState = { status: "loading" } | { status: "error"; message: string } | { status: "ready"; members: PendingMember[] };
type Order = "oldest" | "newest";

const normalize = (value: string) => value.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
/** "2026-11-15" → fecha local; con endOfDay, el final de ese día. */
const fromInput = (value: string, endOfDay = false) => value ? new Date(`${value}T${endOfDay ? "23:59:59.999" : "00:00:00"}`) : null;

/**
 * Validar documentos de nuevos miembros (Funcionalidades del Módulo Web v2.0.0).
 * Se puede buscar por nombre o correo y filtrar por fecha de registro.
 * Cuando un miembro ya no tiene documentos pendientes, su tarjeta desaparece.
 */
export function DocumentValidationList() {
  const [state, setState] = useState<ListState>({ status: "loading" });
  const [query, setQuery] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [order, setOrder] = useState<Order>("oldest");

  useEffect(() => repository.watchPendingMembers(
    members => setState({ status: "ready", members }),
    exception => { console.error(exception); setState({ status: "error", message: firestoreErrorMessage(exception, "consultar los documentos pendientes") }); },
  ), []);

  if (state.status === "loading") return <p className="visitors-hint" role="status">Cargando documentos pendientes…</p>;
  if (state.status === "error") return <p className="visitors-result error" role="alert">{state.message}</p>;

  const search = normalize(query.trim());
  const start = fromInput(from);
  const end = fromInput(to, true);
  const filtered = state.members
    .map(entry => ({ ...entry, created: toDate(entry.member.creationDate), name: entry.client ? `${entry.client.name} ${entry.client.lastName}`.trim() : "Miembro sin datos en clients" }))
    .filter(({ name, client, created }) =>
      normalize(`${name} ${client?.email ?? ""}`).includes(search)
      && (!start || (created !== null && created >= start))
      && (!end || (created !== null && created <= end)))
    .sort((a, b) => ((a.created?.getTime() ?? 0) - (b.created?.getTime() ?? 0)) * (order === "oldest" ? 1 : -1));
  const filtering = search !== "" || from !== "" || to !== "";
  const total = state.members.length;

  return <div className="visitors-stack">
    <div className="doc-filters" role="search">
      <div className="students-search doc-search">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><circle cx="10" cy="10" r="6"/><path d="m15 15 5 5"/></svg>
        <input aria-label="Buscar por nombre o correo" type="search" placeholder="Buscar por nombre o correo..." value={query} onChange={event => setQuery(event.target.value)}/>
      </div>
      <label className="doc-filter-field">Registrado desde<input type="date" value={from} max={to || undefined} onChange={event => setFrom(event.target.value)}/></label>
      <label className="doc-filter-field">Hasta<input type="date" value={to} min={from || undefined} onChange={event => setTo(event.target.value)}/></label>
      <label className="doc-filter-field">Orden<select value={order} onChange={event => setOrder(event.target.value as Order)}><option value="oldest">Más antiguos primero</option><option value="newest">Más recientes primero</option></select></label>
      {filtering && <button type="button" className="settings-outline doc-clear" onClick={() => { setQuery(""); setFrom(""); setTo(""); }}>Limpiar filtros</button>}
    </div>

    <p className="visitors-hint" role="status">
      {total === 0 ? "No hay documentos pendientes de validar."
        : filtering ? `Mostrando ${filtered.length} de ${total} ${total === 1 ? "miembro" : "miembros"} con documentos por validar.`
        : `${total} ${total === 1 ? "miembro tiene" : "miembros tienen"} documentos por validar.`}
    </p>
    {total > 0 && filtered.length === 0 && <p className="doc-empty">Ningún miembro coincide con la búsqueda o las fechas elegidas.</p>}

    <ul className="validation-list">
      {filtered.map(({ member, client, created, name }) => {
        const birthDate = toDate(member.birthDate);
        const age = birthDate ? ageOn(birthDate) : null;
        const photo = safeUrl(member.photoUrl);
        const details = [client?.email, age !== null ? `${age} años${age < 18 ? " · menor de edad" : ""}` : null, created ? `registrado el ${formatDate(created)}` : null].filter(Boolean).join(" · ");
        return <li key={member.uid} className="validation-tile">
          {photo
            // eslint-disable-next-line @next/next/no-img-element -- fotos de Firebase Storage con dominio variable
            ? <a href={photo} target="_blank" rel="noopener noreferrer"><img className="validation-photo" src={photo} alt={`Foto de perfil de ${name}`}/></a>
            : <span className="validation-photo placeholder" aria-hidden="true">{initials(name)}</span>}
          <div className="validation-body">
            <h2>{name}</h2>
            <p>{details}</p>
            <DocumentProgress documents={documentsOf(member)}/>
            <MemberDocumentChecklist member={member} owner={{ name: client?.name ?? name, email: client?.email ?? "" }}/>
          </div>
        </li>;
      })}
    </ul>
  </div>;
}
