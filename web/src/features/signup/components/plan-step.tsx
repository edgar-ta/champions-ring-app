"use client";

import { useState, type FormEvent } from "react";

import { INSCRIPTION_FEE } from "@/src/core/constants/membership";
import { formatCurrency, formatDate, toDate } from "@/src/core/utils/format";
import type { CoreMembershipPlanDuration } from "@/src/core/models/core_membership_plan";
import type { EmailLookup, PlanCatalog, PlanOption, RegistrationKind } from "../models/registration";

export type PlanChoice = { kind: "sample"; plan: null } | { kind: Exclude<RegistrationKind, "sample">; plan: PlanOption };

/** Siempre se muestran estas opciones; si falta su plan en membership_plans, aparecen desactivadas. */
const PLAN_SLOTS: { duration: CoreMembershipPlanDuration; title: string }[] = [
  { duration: "1d", title: "Visita" },
  { duration: "1w", title: "Semana" },
  { duration: "1m", title: "Mes" },
];

/**
 * Paso 2: aquí se decide el tipo de cliente. Clase muestra (prospecto), Visita (ocasional),
 * o Semana / Mes (alumno). La clase muestra solo la puede tomar quien no estaba registrado.
 */
export function PlanStep({ lookup, catalog, initial, onBack, onNext }: {
  lookup: EmailLookup;
  catalog: PlanCatalog;
  initial: PlanChoice | null;
  onBack: () => void;
  onNext: (choice: PlanChoice) => void;
}) {
  const existing = lookup.client;
  const sampleClassDate = toDate(existing?.sampleClassDate);
  const options: { key: string; choice: PlanChoice; title: string; price: string; detail: string; disabled: boolean }[] = [
    {
      key: "sample",
      choice: { kind: "sample", plan: null },
      title: "Clase muestra",
      price: "Gratis",
      detail: existing ? "No disponible: ya estaba registrado en el sistema." : "Una clase sin compromiso. Solo se guardan su nombre, apellidos y correo.",
      disabled: !!existing,
    },
    ...PLAN_SLOTS.map(({ duration, title }) => {
      const membership = duration !== "1d";
      const option = catalog.plans.find(item => item.plan.duration === duration);
      if (!option) {
        return {
          key: `missing-${duration}`,
          choice: { kind: "sample", plan: null } as PlanChoice,
          title,
          price: "No disponible",
          detail: `Falta un plan vigente en membership_plans con duration "${duration}" y cost mayor que 0.`,
          disabled: true,
        };
      }
      return {
        key: option.id,
        choice: { kind: membership ? "membership" : "visit", plan: option } as PlanChoice,
        title,
        price: formatCurrency(option.plan.cost),
        detail: [option.plan.benefits, membership ? `+ ${formatCurrency(INSCRIPTION_FEE)} de inscripción. Pide expediente, documentos y responsiva.` : "Pago de una sola visita."].filter(Boolean).join(" · "),
        disabled: false,
      };
    }),
  ];
  const [selected, setSelected] = useState(initial ? (initial.kind === "sample" ? "sample" : initial.plan.id) : options.find(option => !option.disabled)?.key ?? "");

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const option = options.find(item => item.key === selected && !item.disabled);
    if (option) onNext(option.choice);
  }

  return <form onSubmit={submit}>
    {existing && <div className="visitors-result warning wizard-notice" role="status">
      <p><strong>{existing.name} {existing.lastName}</strong> ya está registrado como cliente con este correo; se usarán sus datos.</p>
      <p>{sampleClassDate ? `Ya tomó su clase muestra el ${formatDate(sampleClassDate)}, así que no puede tomar otra.` : "Como ya estaba registrado, ya no puede tomar una clase muestra."}</p>
    </div>}
    {catalog.ignored.length > 0 && <div className="visitors-result error wizard-notice" role="alert">
      {/* @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ] */}
      <p>Estos documentos de <code>membership_plans</code> no cumplen el Modelo de Datos v22.1.0 y no se pueden usar:</p>
      <ul className="wizard-ignored">{catalog.ignored.map(item => <li key={item.id}><code>{item.id}</code>: {item.reason}.</li>)}</ul>
    </div>}
    <fieldset className="plan-options">
      <legend className="visitors-label">Tipo de registro</legend>
      {options.map(option => <label key={option.key} className={`plan-option ${selected === option.key ? "selected" : ""} ${option.disabled ? "disabled" : ""}`}>
        <input type="radio" name="plan" value={option.key} checked={selected === option.key} disabled={option.disabled} onChange={() => setSelected(option.key)}/>
        <span className="plan-option-title">{option.title}</span>
        <span className="plan-option-price">{option.price}</span>
        <span className="plan-option-detail">{option.detail}</span>
      </label>)}
    </fieldset>
    <div className="visitors-actions wizard-actions"><button type="button" className="settings-outline" onClick={onBack}>Atrás</button><button className="settings-save" type="submit" disabled={!options.some(option => option.key === selected && !option.disabled)}>Continuar</button></div>
  </form>;
}
