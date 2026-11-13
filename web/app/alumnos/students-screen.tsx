"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { DashboardSidebar } from "../components/dashboard-sidebar";

type Student = { id: string; name: string; age: number; membership: string; status: "Activo" | "Por vencer" | "Vencido"; expires: string; tone: string };
const examples: Student[] = [
  { id: "3841", name: "Carlos Mendoza Ruiz", age: 28, membership: "Mensual", status: "Activo", expires: "2025-10-28", tone: "sage" },
  { id: "2842", name: "Regina Soto Alarcón", age: 32, membership: "Semanal", status: "Por vencer", expires: "2025-10-05", tone: "sand" },
  { id: "2843", name: "Mateo Díaz Ramos", age: 15, membership: "Mensual", status: "Activo", expires: "2025-11-15", tone: "blue" },
  { id: "1092", name: "Mario Ortiz Castillos", age: 45, membership: "Día", status: "Vencido", expires: "2025-09-30", tone: "slate" },
  { id: "2845", name: "Andrea Silva Domínguez", age: 24, membership: "Anual", status: "Activo", expires: "2026-08-12", tone: "rose" },
];
const filters = ["Todos", "Activos", "Vencidos", "Por vencer", "Menores"] as const;
const pageSize = 5;
function normalize(value: string) { return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase(); }
function formatDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"][Number(month) - 1]}/${year}`;
}
function Avatar({ student }: { student: Student }) {
  return <span className={`student-avatar ${student.tone}`} aria-hidden="true">{student.name.split(" ").slice(0, 2).map(part => part[0]).join("")}</span>;
}

export function StudentsScreen() {
  const [students, setStudents] = useState(examples);
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<typeof filters[number]>("Todos");
  const [page, setPage] = useState(0);
  const [notice, setNotice] = useState("");
  const [selected, setSelected] = useState<Student | null>(null);
  const registerDialog = useRef<HTMLDialogElement>(null);
  const profileDialog = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    if (new URLSearchParams(window.location.search).get("registrar") === "1") registerDialog.current?.showModal();
  }, []);
  const filtered = students.filter(student => {
    const matchesQuery = normalize(`${student.name} ${student.id}`).includes(normalize(query.trim()));
    const matchesFilter = filter === "Todos" || filter === "Menores" && student.age < 18 || filter === "Activos" && student.status === "Activo" || filter === "Vencidos" && student.status === "Vencido" || filter === "Por vencer" && student.status === "Por vencer";
    return matchesQuery && matchesFilter;
  });
  const visible = filtered.slice(page * pageSize, (page + 1) * pageSize);
  function register(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const student: Student = { id: crypto.randomUUID(), name: String(data.get("name")).trim(), age: Number(data.get("age")), membership: String(data.get("membership")), status: "Activo", expires: String(data.get("expires")), tone: "rose" };
    if (!student.name) return;
    setStudents(current => [...current, student]);
    setQuery(""); setFilter("Todos"); setPage(Math.floor(students.length / pageSize));
    setNotice("Alumno agregado a la vista de demostración. Los cambios se conservan mientras esta página esté abierta.");
    event.currentTarget.reset(); registerDialog.current?.close();
  }

  return <div className="settings-app students-app">
    <DashboardSidebar active={1} onNotice={setNotice}/>
    <main className="settings-main">
      <header className="settings-header"><div><h1>Alumnos</h1><p>Listado de inscritos, estados de membresía y registros rápidos.</p></div><button className="settings-save students-register" type="button" onClick={() => registerDialog.current?.showModal()}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M14 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M8 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M19 8v6m-3-3h6"/></svg>+ Registrar alumno</button></header>
      <div className="settings-content students-content">
        {notice && <div className="settings-notice" role="status">{notice}<button type="button" aria-label="Descartar mensaje" onClick={() => setNotice("")}>×</button></div>}
        <div className="students-toolbar"><div className="students-search"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><circle cx="10" cy="10" r="6"/><path d="m15 15 5 5"/></svg><input aria-label="Buscar alumno por nombre o ID" type="search" placeholder="Buscar alumno por nombre o ID..." value={query} onChange={event => { setQuery(event.target.value); setPage(0); }}/></div><div className="students-filters" role="group" aria-label="Filtrar alumnos">{filters.map(item => <button key={item} type="button" aria-pressed={filter === item} className={filter === item ? "selected" : ""} onClick={() => { setFilter(item); setPage(0); }}>{item}</button>)}</div></div>
        <section className="students-table-panel" aria-label="Listado de alumnos"><div className="students-table-scroll"><table className="students-table"><thead><tr>{["Foto", "Nombre completo", "Edad", "Membresía", "Estado", "Vencimiento", "Acciones"].map(title => <th key={title} scope="col">{title}</th>)}</tr></thead><tbody>{visible.map(student => <tr key={student.id}><td><Avatar student={student}/></td><td className="student-name">{student.name}{student.age < 18 ? " (Menor)" : ""}</td><td>{student.age} años</td><td>{student.membership}</td><td><span className={`student-status ${student.status === "Activo" ? "active" : student.status === "Por vencer" ? "expiring" : "expired"}`}>{student.status}</span></td><td><time dateTime={student.expires}>{formatDate(student.expires)}</time></td><td><button type="button" className="student-profile-button" onClick={() => { setSelected(student); profileDialog.current?.showModal(); }}>Ver Perfil</button></td></tr>)}{visible.length === 0 && <tr><td colSpan={7} className="students-empty">No se encontraron alumnos con estos criterios.</td></tr>}</tbody></table></div><footer className="students-table-footer"><p role="status">Mostrando {visible.length} de {filtered.length} alumnos</p><div><button type="button" disabled={page === 0} onClick={() => setPage(page - 1)}>Anterior</button><button type="button" disabled={(page + 1) * pageSize >= filtered.length} onClick={() => setPage(page + 1)}>Siguiente</button></div></footer></section>
      </div>
    </main>
    <dialog ref={profileDialog} className="students-dialog" aria-labelledby="student-profile-title"><h2 id="student-profile-title">Perfil del alumno</h2>{selected && <><Avatar student={selected}/><h3>{selected.name}</h3><dl><dt>ID</dt><dd>{selected.id}</dd><dt>Edad</dt><dd>{selected.age} años{selected.age < 18 ? " · Menor de edad" : ""}</dd><dt>Membresía</dt><dd>{selected.membership}</dd><dt>Estado</dt><dd>{selected.status}</dd><dt>Vencimiento</dt><dd>{formatDate(selected.expires)}</dd></dl></>}<button className="settings-save" type="button" onClick={() => profileDialog.current?.close()}>Cerrar</button></dialog>
    <dialog ref={registerDialog} className="students-dialog" aria-labelledby="student-register-title"><h2 id="student-register-title">Registrar alumno</h2><p className="students-demo-note">Registro de demostración; todavía no se guarda en Firebase.</p><form onSubmit={register}><label>Nombre completo<input name="name" required maxLength={120}/></label><label>Edad<input name="age" type="number" required min={1} max={120}/></label><label>Membresía<select name="membership">{["Mensual", "Semanal", "Día", "Anual"].map(item => <option key={item}>{item}</option>)}</select></label><label>Vencimiento<input name="expires" type="date" required/></label><div className="students-dialog-actions"><button type="button" className="settings-outline" onClick={() => registerDialog.current?.close()}>Cancelar</button><button type="submit" className="settings-save">Registrar alumno</button></div></form></dialog>
  </div>;
}
