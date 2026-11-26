"use client";

// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

import { PAYMENT_TYPE_LABELS } from "@/src/core/models/core_payment";
import { firestoreErrorMessage } from "@/src/core/utils/firebase-errors";
import { formatCurrency, formatDate, formatTime, startOfToday } from "@/src/core/utils/format";
import { EXPIRING_WINDOW_DAYS, type MemberSummary } from "@/src/features/members/models/member-summary";
import { firebaseMemberRepository } from "@/src/features/members/repositories/firebase-member-repository";
import { firebasePaymentRepository } from "@/src/features/payments/repositories/firebase-payment-repository";
import type { ApprovedPayment } from "@/src/features/payments/repositories/payment-repository";
import { DashboardSidebar } from "../../src/shared/components/dashboard-sidebar";

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

const actions = [
  { label: "Registrar alumno", icon: "register" },
  { label: "Registrar pago", icon: "payment" },
  { label: "Buscar alumno", icon: "search" },
  { label: "Nueva venta", icon: "sale" },
] as const;

/** Días hacia atrás que cubre la actividad reciente. */
const ACTIVITY_DAYS = 7;
const ACTIVITY_LIMIT = 8;

type Activity = { key: string; title: string; description: string; date: Date; tone: "green" | "pink" };

type DashboardData = { members: MemberSummary[]; payments: ApprovedPayment[] };
type LoadState = { status: "loading" } | { status: "error"; message: string } | { status: "ready"; data: DashboardData };

function recentActivity({ members, payments }: DashboardData, since: Date): Activity[] {
  const events: Activity[] = [
    ...payments.map(payment => ({
      key: `payment-${payment.uid}`,
      title: "Pago registrado",
      description: `${payment.payerName ?? "Cliente sin nombre"} pagó ${formatCurrency(payment.amount)} (${PAYMENT_TYPE_LABELS[payment.type] ?? payment.type})`,
      date: payment.approvalDate,
      tone: "pink" as const,
    })),
    ...members.filter(member => member.creationDate && member.creationDate >= since).map(member => ({
      key: `member-${member.uid}`,
      title: "Nuevo alumno registrado",
      description: `${member.fullName}${member.age !== null && member.age < 18 ? ` (Menor)${member.guardianName ? ` - Tutor: ${member.guardianName}` : ""}` : ""}`,
      date: member.creationDate!,
      tone: "green" as const,
    })),
  ];
  return events.sort((a, b) => b.date.getTime() - a.date.getTime()).slice(0, ACTIVITY_LIMIT);
}

export function ReceptionDashboard() {
  const router = useRouter();
  const [notice, setNotice] = useState("");
  const [state, setState] = useState<LoadState>({ status: "loading" });
  const [activitySince] = useState(() => { const date = startOfToday(); date.setDate(date.getDate() - (ACTIVITY_DAYS - 1)); return date; });

  useEffect(() => {
    let active = true;
    Promise.all([firebaseMemberRepository.listMembers(), firebasePaymentRepository.listApprovedSince(activitySince)])
      .then(([members, payments]) => { if (active) setState({ status: "ready", data: { members, payments } }); })
      .catch(error => { console.error(error); if (active) setState({ status: "error", message: firestoreErrorMessage(error, "cargar el resumen del día") }); });
    return () => { active = false; };
  }, [activitySince]);

  const data = state.status === "ready" ? state.data : null;
  const today = startOfToday();
  const todaysPayments = data?.payments.filter(payment => payment.approvalDate >= today) ?? [];
  const metrics = [
    { label: "Alumnos activos", value: data ? String(data.members.filter(member => member.status === "active" || member.status === "expiring").length) : "…", icon: "students", tone: "green" },
    { label: `Membresías por vencer (${EXPIRING_WINDOW_DAYS} días)`, value: data ? String(data.members.filter(member => member.status === "expiring").length) : "…", icon: "expiry", tone: "amber" },
    { label: "Pagos del día", value: data ? formatCurrency(todaysPayments.reduce((total, payment) => total + payment.amount, 0)) : "…", icon: "money", tone: "pink" },
    // El Modelo de Datos v20.0.0 todavía no tiene una colección de ventas.
    { label: "Ventas del día", value: "—", icon: "cart", tone: "pink" },
  ] as const;
  const activity = data ? recentActivity(data, activitySince) : [];

  return <div className="settings-app reception-app">
    <DashboardSidebar onNotice={setNotice}/>
    <main className="settings-main">
      <header className="settings-header"><div><h1>Panel de recepción</h1><p>Resumen de actividad diaria del gimnasio.</p></div></header>
      <div className="settings-content reception-content">
        {notice && <div className="settings-notice" role="status" aria-live="polite">{notice}<button type="button" aria-label="Descartar mensaje" onClick={() => setNotice("")}>×</button></div>}
        {state.status === "error" && <div className="settings-notice" role="alert">{state.message}</div>}
        <section className="reception-metrics" aria-label="Resumen del día" aria-busy={state.status === "loading"}>
          {metrics.map(metric => <article className="reception-metric" key={metric.label}><span className={`reception-metric-icon ${metric.tone}`}><DashboardIcon name={metric.icon}/></span><div><h2>{metric.label}</h2><p>{metric.value}</p></div></article>)}
        </section>
        <div className="reception-columns">
          <section className="reception-actions" aria-labelledby="actions-title"><h2 id="actions-title">Acciones rápidas</h2><div className="reception-action-list">{actions.map(action => <button type="button" key={action.label} className="reception-action" onClick={() => action.icon === "search" ? router.push("/alumnos") : action.icon === "register" ? router.push("/alumnos/registrar") : setNotice(`La función «${action.label}» aún no está disponible.`)}><span className={`reception-action-icon ${action.icon === "register" ? "pink" : ""}`}><DashboardIcon name={action.icon}/></span><span>{action.label}</span><svg className="reception-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="m9 6 6 6-6 6"/></svg></button>)}</div></section>
          <section className="reception-activity" aria-labelledby="activity-title"><h2 id="activity-title">Actividad reciente</h2><ol className="reception-timeline">
            {state.status === "loading" && <li className="reception-empty">Cargando actividad…</li>}
            {state.status === "ready" && activity.length === 0 && <li className="reception-empty">Sin pagos ni alumnos nuevos en los últimos {ACTIVITY_DAYS} días.</li>}
            {activity.map(item => <li key={item.key}><span className={`reception-dot ${item.tone}`} aria-hidden="true"/><div className="reception-event"><div className="reception-event-heading"><h3>{item.title}</h3><time dateTime={item.date.toISOString()}>{item.date >= today ? formatTime(item.date) : formatDate(item.date)}</time></div><p>{item.description}</p></div></li>)}
          </ol></section>
        </div>
      </div>
    </main>
  </div>;
}
