"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { DashboardSidebar } from "../components/dashboard-sidebar";

const icons = {
  students: "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M17 4a4 4 0 0 1 0 8M22 21v-2a4 4 0 0 0-3-4",
  expiry: "m12 2 3 2 4 1 1 4 2 3-2 3-1 4-4 1-3 2-3-2-4-1-1-4-2-3 2-3 1-4 4-1ZM12 7v6m0 3v.1",
  money: "M3 6h18v12H3ZM7 11v2m10-2v2M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6",
  cart: "M2 3h3l3 13h11l3-9H6M9 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2M18 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2",
  register: "M15 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M19 8v6m-3-3h6",
  payment: "M4 6h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1ZM3 10h18",
  search: "M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14M16 16l5 5",
  sale: "M3 3h9l9 9-9 9-9-9ZM7 7h.01",
};

function DashboardIcon({ name }: { name: keyof typeof icons }) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={icons[name]}/></svg>;
}

// Reference values for the UI; replace with reception data when its repository is available.
const metrics = [
  { label: "Alumnos activos", value: "348", icon: "students", tone: "green" },
  { label: "Membresías por vencer", value: "14", icon: "expiry", tone: "amber" },
  { label: "Pagos del día", value: "$4,850.00", icon: "money", tone: "pink" },
  { label: "Ventas del día", value: "$2,100.00", icon: "cart", tone: "pink" },
] as const;
const actions = [
  { label: "Registrar alumno", icon: "register" },
  { label: "Registrar pago", icon: "payment" },
  { label: "Buscar alumno", icon: "search" },
  { label: "Nueva venta", icon: "sale" },
] as const;
const activity = [
  { title: "Acceso concedido", description: "Carlos Mendoza (ID: #3841) - Membresía Mensual", time: "09:42 AM", dateTime: "09:42", tone: "green" },
  { title: "Pago registrado", description: "Regina Soto pagó $950.00 (Efectivo) - Membresía Mensual", time: "09:35 AM", dateTime: "09:35", tone: "pink" },
  { title: "Acceso denegado", description: "Mario Ortiz (ID: #1092) - Membresía vencida hace 4 días", time: "09:12 AM", dateTime: "09:12", tone: "red" },
  { title: "Nuevo alumno registrado", description: "Sofía Martínez (Menor) - Tutor asignado: Andrea Silva", time: "08:50 AM", dateTime: "08:50", tone: "green" },
];

export function ReceptionDashboard() {
  const router = useRouter();
  const [notice, setNotice] = useState("");
  return <div className="settings-app reception-app">
    <DashboardSidebar active={0} onNotice={setNotice}/>
    <main className="settings-main">
      <header className="settings-header"><div><h1>Panel de recepción</h1><p>Resumen de actividad diaria y accesos del gimnasio.</p></div></header>
      <div className="settings-content reception-content">
        {notice && <div className="settings-notice" role="status" aria-live="polite">{notice}<button type="button" aria-label="Descartar mensaje" onClick={() => setNotice("")}>×</button></div>}
        <section className="reception-metrics" aria-label="Resumen del día">
          {metrics.map(metric => <article className="reception-metric" key={metric.label}><span className={`reception-metric-icon ${metric.tone}`}><DashboardIcon name={metric.icon}/></span><div><h2>{metric.label}</h2><p>{metric.value}</p></div></article>)}
        </section>
        <div className="reception-columns">
          <section className="reception-actions" aria-labelledby="actions-title"><h2 id="actions-title">Acciones rápidas</h2><div className="reception-action-list">{actions.map(action => <button type="button" key={action.label} className="reception-action" onClick={() => action.icon === "register" ? router.push("/alumnos?registrar=1") : action.icon === "search" ? router.push("/alumnos") : setNotice(`La función «${action.label}» aún no está disponible.`)}><span className={`reception-action-icon ${action.icon === "register" ? "pink" : ""}`}><DashboardIcon name={action.icon}/></span><span>{action.label}</span><svg className="reception-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="m9 6 6 6-6 6"/></svg></button>)}</div></section>
          <section className="reception-activity" aria-labelledby="activity-title"><h2 id="activity-title">Actividad reciente</h2><ol className="reception-timeline">{activity.map(item => <li key={item.title}><span className={`reception-dot ${item.tone}`} aria-hidden="true"/><div className="reception-event"><div className="reception-event-heading"><h3>{item.title}</h3><time dateTime={item.dateTime}>{item.time}</time></div><p>{item.description}</p></div></li>)}</ol></section>
        </div>
      </div>
    </main>
  </div>;
}
