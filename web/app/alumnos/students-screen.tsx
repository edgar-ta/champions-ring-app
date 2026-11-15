"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";

import { hasPendingDocuments, type Member } from "@/app/core/models/member";
import { firestoreErrorMessage } from "@/app/core/utils/firebase-errors";
import { formatDate } from "@/app/core/utils/format";
import { STATUS_LABELS, type MemberSummary, type MembershipStatus } from "@/app/features/members/models/member-summary";
import { VISITOR_LABELS, type VisitorKind, type VisitorSummary } from "@/app/features/members/models/visitor-summary";
import { firebaseMemberRepository } from "@/app/features/members/repositories/firebase-member-repository";
import { DashboardSidebar } from "../components/dashboard-sidebar";
import { documentsOf } from "@/app/features/document-validation/components/member-documents";
import { Avatar, StudentProfile, formatDateTime, isMinor, type Row } from "./student-profile";

const filters = ["Todos", "Activos", "Por vencer", "Vencidos", "Sin membresía", "Docs. pendientes", "Menores", "Visitas", "Clase muestra"] as const;
type Filter = typeof filters[number];
const filterStatus: Partial<Record<Filter, MembershipStatus>> = { "Activos": "active", "Por vencer": "expiring", "Vencidos": "expired", "Sin membresía": "none" };
const filterKind: Partial<Record<Filter, VisitorKind>> = { "Visitas": "visit", "Clase muestra": "sample" };
const pageSize = 10;

type LoadState = { status: "loading" } | { status: "error"; message: string } | { status: "ready"; rows: Row[] };

function normalize(value: string) { return value.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase(); }
const rowKey = (row: Row) => `${row.kind}-${row.uid}`;

/** Resumen de documentos de un alumno para la tabla: completos, cuántos faltan o cuántos se rechazaron. */
function documentStatus(row: Row): { label: string; detail: string; tone: "done" | "pending" | "rejected" } | null {
  if (row.kind !== "member") return null;
  const documents = documentsOf(row.member.record);
  const validated = documents.filter(document => document.validated).length;
  const rejected = documents.filter(document => document.rejection).length;
  const missing = documents.length - validated;
  const detail = `${validated} de ${documents.length} validados`;
  if (missing === 0) return { label: "Completos", detail, tone: "done" };
  if (rejected > 0) return { label: rejected === 1 ? "1 rechazado" : `${rejected} rechazados`, detail: missing > rejected ? `${detail} · ${missing - rejected} por revisar` : detail, tone: "rejected" };
  return { label: missing === 1 ? "Falta 1" : `Faltan ${missing}`, detail, tone: "pending" };
}

function toRows(members: MemberSummary[], visitors: VisitorSummary[]): Row[] {
  const rows: Row[] = [
    ...members.map(member => ({ kind: "member" as const, uid: member.uid, fullName: member.fullName, email: member.email, sortDate: member.creationDate?.getTime() ?? 0, member })),
    ...visitors.map(visitor => ({ kind: visitor.kind, uid: visitor.uid, fullName: visitor.fullName, email: visitor.email, sortDate: (visitor.lastDate ?? visitor.creationDate)?.getTime() ?? 0, visitor })),
  ];
  // Lo más reciente primero: el registro del alumno, o la última visita o clase muestra.
  return rows.sort((a, b) => b.sortDate - a.sortDate);
}

/** Celdas de Membresía, Estado y Fecha según el tipo de fila. */
function rowDetails(row: Row): { plan: string; status: string; statusClass: string; date: Date | null; dateLabel: string } {
  if (row.kind === "member") {
    const { member } = row;
    return { plan: member.planLabel ?? "—", status: STATUS_LABELS[member.status], statusClass: member.status, date: member.membershipEnd, dateLabel: "Vence" };
  }
  const { visitor } = row;
  return {
    plan: row.kind === "visit" ? `Visita${visitor.visits.length > 1 ? ` (${visitor.visits.length})` : ""}` : "Clase muestra",
    status: VISITOR_LABELS[row.kind],
    statusClass: row.kind,
    date: visitor.lastDate,
    dateLabel: row.kind === "visit" ? "Última visita" : "Clase muestra",
  };
}

export function StudentsScreen() {
  const [state, setState] = useState<LoadState>({ status: "loading" });
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<Filter>("Todos");
  const [page, setPage] = useState(0);
  const [notice, setNotice] = useState("");
  const [selectedKey, setSelectedKey] = useState<string | null>(null);
  const profileDialog = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      const members = await firebaseMemberRepository.listMembers();
      const visitors = await firebaseMemberRepository.listVisitors(new Set(members.map(member => member.uid)));
      return toRows(members, visitors);
    })()
      .then(rows => { if (active) setState({ status: "ready", rows }); })
      .catch(error => { console.error(error); if (active) setState({ status: "error", message: firestoreErrorMessage(error, "cargar los alumnos") }); });
    return () => { active = false; };
  }, []);

  const rows = state.status === "ready" ? state.rows : [];
  const selected = rows.find(row => rowKey(row) === selectedKey) ?? null;

  /** Al validar o rechazar un documento desde el perfil, se actualiza la fila sin volver a consultar todo. */
  function updateMember(uid: string, patch: Partial<Member>) {
    setState(current => current.status !== "ready" ? current : {
      status: "ready",
      rows: current.rows.map(row => {
        if (row.kind !== "member" || row.uid !== uid) return row;
        const record = { ...row.member.record, ...patch };
        return { ...row, member: { ...row.member, record, documentsValidated: !hasPendingDocuments(record) } };
      }),
    });
  }

  function closeProfile() { profileDialog.current?.close(); }
  const search = normalize(query.trim());
  const filtered = rows.filter(row => {
    const matchesQuery = normalize(`${row.fullName} ${row.email}`).includes(search);
    const matchesFilter = filter === "Todos"
      || (filter === "Menores" && isMinor(row))
      || (filter === "Docs. pendientes" && row.kind === "member" && !row.member.documentsValidated)
      || (filterStatus[filter] !== undefined && row.kind === "member" && row.member.status === filterStatus[filter])
      || (filterKind[filter] !== undefined && row.kind === filterKind[filter]);
    return matchesQuery && matchesFilter;
  });
  const visible = filtered.slice(page * pageSize, (page + 1) * pageSize);

  return <div className="settings-app students-app">
    <DashboardSidebar onNotice={setNotice}/>
    <main className="settings-main">
      <header className="settings-header"><div><h1>Alumnos</h1><p>Alumnos inscritos, visitas y clases muestra.</p></div><Link className="settings-save students-register" href="/alumnos/registrar"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M14 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M8 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M19 8v6m-3-3h6"/></svg>+ Registrar alumno</Link></header>
      <div className="settings-content students-content">
        {notice && <div className="settings-notice" role="status">{notice}<button type="button" aria-label="Descartar mensaje" onClick={() => setNotice("")}>×</button></div>}
        {state.status === "error" && <div className="settings-notice" role="alert">{state.message}</div>}
        <div className="students-toolbar"><div className="students-search"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><circle cx="10" cy="10" r="6"/><path d="m15 15 5 5"/></svg><input aria-label="Buscar por nombre o correo" type="search" placeholder="Buscar por nombre o correo..." value={query} onChange={event => { setQuery(event.target.value); setPage(0); }}/></div><div className="students-filters" role="group" aria-label="Filtrar">{filters.map(item => <button key={item} type="button" aria-pressed={filter === item} className={filter === item ? "selected" : ""} onClick={() => { setFilter(item); setPage(0); }}>{item}</button>)}</div></div>
        <section className="students-table-panel" aria-label="Listado de alumnos, visitas y clases muestra" aria-busy={state.status === "loading"}><div className="students-table-scroll"><table className="students-table"><thead><tr>{["Foto", "Nombre completo", "Edad", "Membresía", "Estado", "Documentos", "Fecha", "Acciones"].map(title => <th key={title} scope="col">{title}</th>)}</tr></thead><tbody>
          {visible.map(row => {
            const details = rowDetails(row);
            const documents = documentStatus(row);
            return <tr key={rowKey(row)}>
              <td><Avatar row={row}/></td>
              <td className="student-name">{row.fullName}{isMinor(row) ? " (Menor)" : ""}</td>
              <td>{row.kind === "member" && row.member.age !== null ? `${row.member.age} años` : "—"}</td>
              <td>{details.plan}</td>
              <td><span className={`student-status ${details.statusClass}`}>{details.status}</span></td>
              <td>{documents ? <span className={`student-docs ${documents.tone}`} title={documents.detail}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={documents.tone === "done" ? "m5 12 4.5 4.5L19 7" : documents.tone === "rejected" ? "M12 8v5M12 16.5v.5M10.3 3.9 2.6 17.5A2 2 0 0 0 4.3 20.5h15.4a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0" : "M12 7v5l3 2M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18"}/></svg>
                <span>{documents.label}<small>{documents.detail}</small></span>
              </span> : <span className="student-docs none">—</span>}</td>
              <td>{details.date ? <><small className="student-date-label">{details.dateLabel}</small><time dateTime={details.date.toISOString()}>{row.kind === "member" ? formatDate(details.date) : formatDateTime(details.date)}</time></> : "—"}</td>
              <td><button type="button" className="student-profile-button" onClick={() => { setSelectedKey(rowKey(row)); profileDialog.current?.showModal(); }}>Ver Perfil</button></td>
            </tr>;
          })}
          {visible.length === 0 && <tr><td colSpan={8} className="students-empty">{state.status === "loading" ? "Cargando alumnos…" : state.status === "error" ? "No se pudieron cargar los alumnos." : rows.length === 0 ? "Todavía no hay registros." : "No se encontraron registros con estos criterios."}</td></tr>}
        </tbody></table></div><footer className="students-table-footer"><p role="status">Mostrando {visible.length} de {filtered.length} registros</p><div><button type="button" disabled={page === 0} onClick={() => setPage(page - 1)}>Anterior</button><button type="button" disabled={(page + 1) * pageSize >= filtered.length} onClick={() => setPage(page + 1)}>Siguiente</button></div></footer></section>
      </div>
    </main>
    <dialog ref={profileDialog} className="students-dialog profile-dialog" aria-labelledby="student-profile-title" onClose={() => setSelectedKey(null)} onClick={event => { if (event.target === event.currentTarget) closeProfile(); }}>
      {selected && <StudentProfile row={selected} onClose={closeProfile} onUpdated={patch => updateMember(selected.uid, patch)}/>}
    </dialog>
  </div>;
}
