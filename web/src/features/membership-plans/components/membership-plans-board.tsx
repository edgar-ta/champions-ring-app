"use client";

// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
import { useCallback, useEffect, useRef, useState, type FormEvent } from "react";

import { PanelShell } from "@/src/shared/components/panel-shell";
import type { CoreMembershipPlanDuration } from "@/src/core/models/core_membership_plan";
import { firestoreErrorMessage } from "@/src/core/utils/firebase-errors";
import { formatCurrency } from "@/src/core/utils/format";
import { firebaseMemberRepository } from "@/src/features/members/repositories/firebase-member-repository";
import { firebaseMembershipPlanRepository as repository } from "../repositories/firebase-membership-plan-repository";
import type { PlanRecord } from "../repositories/membership-plan-repository";

const DURATIONS: { value: CoreMembershipPlanDuration; title: string; length: string }[] = [
  { value: "1d", title: "Día", length: "24 Horas" },
  { value: "1w", title: "Semana", length: "7 Días" },
  { value: "1m", title: "Mes", length: "30 Días" },
];
const durationInfo = (value: string) => DURATIONS.find(item => item.value === value);

type BoardState = { status: "loading" } | { status: "error"; message: string } | { status: "ready"; plans: PlanRecord[]; enrolled: Map<string, number> };

/** Membresías: planes de `membership_plans` con su precio, duración y alumnos con membresía vigente. */
export function MembershipPlansBoard() {
  const [state, setState] = useState<BoardState>({ status: "loading" });
  const [editing, setEditing] = useState<PlanRecord | "new" | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState("");
  const dialog = useRef<HTMLDialogElement>(null);

  const load = useCallback(async () => {
    const [plans, members] = await Promise.all([repository.listPlans(), firebaseMemberRepository.listMembers()]);
    const enrolled = new Map<string, number>();
    for (const member of members) {
      if (member.planId && (member.status === "active" || member.status === "expiring")) enrolled.set(member.planId, (enrolled.get(member.planId) ?? 0) + 1);
    }
    return { plans, enrolled };
  }, []);

  const refresh = useCallback(() => load()
    .then(data => setState({ status: "ready", ...data }))
    .catch(exception => { console.error(exception); setState({ status: "error", message: firestoreErrorMessage(exception, "cargar las membresías") }); }), [load]);

  useEffect(() => {
    let active = true;
    load()
      .then(data => { if (active) setState({ status: "ready", ...data }); })
      .catch(exception => { console.error(exception); if (active) setState({ status: "error", message: firestoreErrorMessage(exception, "cargar las membresías") }); });
    return () => { active = false; };
  }, [load]);

  function open(target: PlanRecord | "new") { setEditing(target); setError(""); dialog.current?.showModal(); }
  function close() { dialog.current?.close(); setEditing(null); }

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const input = { duration: String(data.get("duration")) as CoreMembershipPlanDuration, cost: Number(data.get("cost")), benefits: String(data.get("benefits")) };
    setBusy("save"); setError("");
    try {
      if (editing === "new") await repository.createPlan(input);
      else if (editing) await repository.updatePlan(editing.id, input);
      close();
      await refresh();
    } catch (exception) {
      console.error(exception);
      setError(firestoreErrorMessage(exception, "guardar el plan"));
    } finally { setBusy(null); }
  }

  async function toggle(record: PlanRecord) {
    const title = durationInfo(record.plan.duration)?.title ?? record.plan.duration;
    if (record.active && !window.confirm(`¿Desactivar el plan ${title}? Ya no se podrá elegir al registrar alumnos. Los alumnos que ya lo tienen lo conservan.`)) return;
    setBusy(record.id); setError("");
    try {
      await (record.active ? repository.deactivatePlan(record.id) : repository.reactivatePlan(record.id));
      await refresh();
    } catch (exception) {
      console.error(exception);
      setError(firestoreErrorMessage(exception, record.active ? "desactivar el plan" : "reactivar el plan"));
    } finally { setBusy(null); }
  }

  const plans = state.status === "ready" ? state.plans : [];
  // El registro usa un solo plan activo por duración: se avisa si hay más de uno.
  const duplicated = DURATIONS.filter(({ value }) => plans.filter(record => record.active && record.plan.duration === value).length > 1);
  const current = editing && editing !== "new" ? editing.plan : null;

  return <PanelShell wide title="Membresías" description="Configuración de planes, precios y control de alumnos activos por tipo de membresía."
    action={<button type="button" className="settings-save" onClick={() => open("new")}>+ Crear nuevo plan</button>}>
    {state.status === "loading" && <p className="visitors-hint" role="status">Cargando membresías…</p>}
    {state.status === "error" && <p className="visitors-result error" role="alert">{state.message}</p>}
    {error && !editing && <p className="visitors-result error plans-notice" role="alert">{error}</p>}
    {duplicated.length > 0 && <p className="visitors-result warning plans-notice" role="status">Hay más de un plan activo de {duplicated.map(item => item.title).join(" y ")}. Al registrar alumnos solo se ofrece uno por duración; desactiva los que sobren.</p>}
    {state.status === "ready" && plans.length === 0 && <p className="visitors-hint">Todavía no hay planes. Crea uno de Día (visita), Semana y Mes.</p>}
    <div className="plans-grid">
      {plans.map(record => {
        const info = durationInfo(record.plan.duration);
        const enrolled = state.status === "ready" ? state.enrolled.get(record.id) ?? 0 : 0;
        return <article key={record.id} className={`plan-card ${record.active ? "" : "inactive"}`}>
          <header><h2>{info?.title ?? record.plan.duration}</h2><span className={`plan-badge ${record.active ? "active" : ""}`}>{record.active ? "Activo" : "Inactivo"}</span></header>
          <p className="plan-price">{typeof record.plan.cost === "number" ? formatCurrency(record.plan.cost) : "Sin precio"}</p>
          <p className="plan-duration">Duración: {info?.length ?? `"${record.plan.duration}" no es válida`}</p>
          <hr/>
          <p className="plan-benefits">{record.plan.benefits || "Sin descripción."}</p>
          <p className="plan-enrolled"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M17 4a4 4 0 0 1 0 8M22 21v-2a4 4 0 0 0-3-4"/></svg>{enrolled} {enrolled === 1 ? "Alumno inscrito" : "Alumnos inscritos"}</p>
          <div className="plan-actions">
            <button type="button" onClick={() => open(record)} disabled={busy !== null}>Editar</button>
            <button type="button" onClick={() => toggle(record)} disabled={busy !== null}>{busy === record.id ? "Guardando…" : record.active ? "Desactivar" : "Reactivar"}</button>
          </div>
        </article>;
      })}
    </div>

    <dialog ref={dialog} className="students-dialog" aria-labelledby="plan-dialog-title" onClose={() => setEditing(null)}>
      <h2 id="plan-dialog-title">{editing === "new" ? "Crear nuevo plan" : "Editar plan"}</h2>
      {editing && <form key={editing === "new" ? "new" : editing.id} onSubmit={save}>
        <label>Duración
          <select name="duration" defaultValue={current && durationInfo(current.duration) ? current.duration : "1m"} required>
            {DURATIONS.map(item => <option key={item.value} value={item.value}>{item.title} ({item.length})</option>)}
          </select>
        </label>
        <label>Precio (MXN)<input name="cost" type="number" min={1} step="0.01" required defaultValue={typeof current?.cost === "number" ? current.cost : ""}/></label>
        <label>Beneficios<textarea name="benefits" rows={3} maxLength={300} defaultValue={current?.benefits ?? ""} placeholder="Ej. Clases de boxeo ilimitadas y acceso a todas las áreas"/></label>
        {error && <p className="visitors-result error" role="alert">{error}</p>}
        <div className="students-dialog-actions"><button type="button" className="settings-outline" onClick={close} disabled={busy === "save"}>Cancelar</button><button type="submit" className="settings-save" disabled={busy === "save"}>{busy === "save" ? "Guardando…" : "Guardar"}</button></div>
      </form>}
    </dialog>
  </PanelShell>;
}
