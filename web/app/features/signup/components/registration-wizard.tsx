"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { PAYMENT_TYPE_LABELS } from "@/app/core/models/payment";
import { firestoreErrorMessage } from "@/app/core/utils/firebase-errors";
import { formatCurrency } from "@/app/core/utils/format";
import { useReceptionist } from "@/app/features/authentication/components/receptionist-session";
import type { EmailLookup, PaymentDetails, PersonalData, PlanCatalog } from "../models/registration";
import { firebaseRegistrationRepository as repository, RegistrationError } from "../repositories/firebase-registration-repository";
import { MemberRegistrationForm, type MemberRegistration } from "./member-registration-form";
import { PaymentStep } from "./payment-step";
import { PersonalStep } from "./personal-step";
import { PlanStep, type PlanChoice } from "./plan-step";

type StepId = "personal" | "plan" | "member" | "payment" | "summary";
const STEP_TITLES: Record<StepId, string> = { personal: "Datos personales", plan: "Membresía", member: "Registro del alumno", payment: "Pago", summary: "Confirmar" };

/** Los pasos dependen del tipo de cliente elegido en Membresía. */
function stepsFor(choice: PlanChoice | null): StepId[] {
  if (choice?.kind === "membership") return ["personal", "plan", "member"];
  if (choice?.kind === "visit") return ["personal", "plan", "payment", "summary"];
  return ["personal", "plan", "summary"];
}

type PlansState = { status: "loading" } | { status: "error"; message: string } | { status: "ready"; catalog: PlanCatalog };
type Result = { title: string; lines: string[]; warnings: string[] };

/**
 * Registro desde cero en recepción. Primero nombre, apellidos y correo (se busca si ya existe);
 * en Membresía se decide el tipo: clase muestra, visita, o Semana / Mes, que abre el registro completo.
 */
export function RegistrationWizard() {
  const receptionist = useReceptionist();
  const [plans, setPlans] = useState<PlansState>({ status: "loading" });
  const [step, setStep] = useState<StepId>("personal");
  const [personal, setPersonal] = useState<PersonalData | null>(null);
  const [lookup, setLookup] = useState<EmailLookup | null>(null);
  const [choice, setChoice] = useState<PlanChoice | null>(null);
  const [payment, setPayment] = useState<PaymentDetails | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState<Result | null>(null);

  useEffect(() => {
    let active = true;
    repository.listPlans()
      .then(list => { if (active) setPlans({ status: "ready", catalog: list }); })
      .catch(exception => { console.error(exception); if (active) setPlans({ status: "error", message: firestoreErrorMessage(exception, "cargar los planes de membresía") }); });
    return () => { active = false; };
  }, []);

  const steps = stepsFor(choice);
  const back = () => { setError(""); setStep(steps[steps.indexOf(step) - 1]); };
  const name = (lookup?.client ? `${lookup.client.name} ${lookup.client.lastName}` : `${personal?.name ?? ""} ${personal?.lastName ?? ""}`).trim();
  const membershipPlans = plans.status === "ready" ? plans.catalog.plans.filter(option => option.plan.duration !== "1d") : [];
  const visitLines = choice?.kind === "visit" ? [{ label: "Visita", amount: choice.plan.plan.cost }] : [];

  function restart() {
    setStep("personal"); setPersonal(null); setLookup(null); setChoice(null); setPayment(null); setError(""); setResult(null);
  }

  async function run(task: () => Promise<Result>) {
    if (busy) return;
    setBusy(true); setError("");
    try { setResult(await task()); }
    catch (exception) {
      console.error(exception);
      setError(exception instanceof RegistrationError ? exception.message : firestoreErrorMessage(exception, "completar el registro"));
    } finally { setBusy(false); }
  }

  function confirmSimple() {
    if (!personal || !lookup || !choice) return;
    void run(async () => {
      if (choice.kind === "sample") {
        await repository.registerSampleClass(personal);
        return { title: "Prospecto registrado", lines: [`${name} puede tomar hoy su clase muestra.`], warnings: [] };
      }
      if (choice.kind !== "visit" || !payment) throw new Error("Falta el pago de la visita.");
      await repository.registerVisit({ personal, existing: lookup.client, plan: choice.plan, payment, receptionistUid: receptionist.uid });
      return { title: "Visita registrada", lines: [`Se registró la visita de ${name} (${PAYMENT_TYPE_LABELS[payment.type]}).`, ...(payment.type === "mercado-pago" ? ["El pago queda pendiente de confirmación con Mercado Pago."] : [])], warnings: [] };
    });
  }

  function registerMember(registration: MemberRegistration) {
    if (!lookup) return;
    void run(async () => {
      const outcome = await repository.registerMember({ ...registration, existing: lookup.client, receptionistUid: receptionist.uid });
      const fullName = `${registration.personal.name} ${registration.personal.lastName}`;
      return {
        title: "Alumno registrado",
        lines: [
          outcome.activated ? `La membresía de ${fullName} está activa.` : `${fullName} quedó registrado; su membresía se activará cuando se confirme el pago.`,
          `Se envió un correo a ${registration.personal.email.toLowerCase()} para que elija la contraseña de su cuenta en la app.`,
          "Sus documentos quedan pendientes de validar en la sección Documentos.",
        ],
        warnings: outcome.warnings,
      };
    });
  }

  if (result) return <section className="settings-panel visitors-panel signup-narrow" aria-labelledby="signup-result-title">
    <h2 id="signup-result-title">{result.title}</h2>
    <div className="visitors-result success">{result.lines.map(line => <p key={line}>{line}</p>)}</div>
    {result.warnings.length > 0 && <div className="visitors-result warning" role="alert">{result.warnings.map(line => <p key={line}>{line}</p>)}</div>}
    <div className="visitors-actions wizard-actions"><Link className="settings-outline" href="/alumnos">Ver alumnos</Link><button type="button" className="settings-save" onClick={restart}>Registrar a otra persona</button></div>
  </section>;

  const position = steps.indexOf(step);
  const stepper = <ol className="wizard-steps" aria-label="Pasos del registro">
    {steps.map((id, index) => <li key={id} className={index === position ? "current" : index < position ? "done" : ""} aria-current={index === position ? "step" : undefined}>{STEP_TITLES[id]}</li>)}
  </ol>;

  // El registro completo del alumno ocupa todo el ancho, como en el diseño.
  if (step === "member" && personal && lookup && choice?.kind === "membership") return <div className="signup-member">
    {stepper}
    <MemberRegistrationForm personal={personal} existing={lookup.client} plans={membershipPlans} initialPlan={choice.plan} busy={busy} error={error} onBack={back} onSubmit={registerMember}/>
  </div>;

  return <section className="settings-panel visitors-panel signup-narrow" aria-labelledby="signup-step-title">
    {stepper}
    <h2 id="signup-step-title">{STEP_TITLES[step]}</h2>

    {step === "personal" && <PersonalStep initial={personal} onNext={(data, found) => {
      // Cambiar de persona invalida lo que se haya elegido después.
      if (data.email.toLowerCase() !== personal?.email.toLowerCase()) { setChoice(null); setPayment(null); }
      setPersonal(data); setLookup(found); setStep("plan");
    }}/>}

    {step === "plan" && lookup && (plans.status === "ready"
      ? <PlanStep lookup={lookup} catalog={plans.catalog} initial={choice} onBack={back} onNext={selected => {
          if (selected.kind !== choice?.kind || selected.plan?.id !== choice?.plan?.id) setPayment(null);
          setChoice(selected);
          setStep(stepsFor(selected)[2]);
        }}/>
      : plans.status === "loading" ? <p className="visitors-hint" role="status">Cargando planes…</p>
      : <p className="visitors-result error" role="alert">{plans.message}</p>)}

    {step === "payment" && <PaymentStep lines={visitLines} initial={payment} onBack={back} onNext={data => { setPayment(data); setStep("summary"); }}/>}

    {step === "summary" && personal && choice && <>
      <dl className="wizard-summary">
        <dt>Nombre</dt><dd>{name}</dd>
        <dt>Correo</dt><dd>{personal.email.toLowerCase()}</dd>
        <dt>Tipo</dt><dd>{choice.kind === "sample" ? "Prospecto · clase muestra gratis" : "Usuario ocasional · visita"}</dd>
        {lookup?.client && <><dt>Registro previo</dt><dd>Ya era cliente; se reutilizan sus datos.</dd></>}
        {payment && choice.kind === "visit" && <><dt>Pago</dt><dd>{formatCurrency(choice.plan.plan.cost)} · {PAYMENT_TYPE_LABELS[payment.type]}</dd></>}
      </dl>
      {error && <p className="visitors-result error" role="alert">{error}</p>}
      <div className="visitors-actions wizard-actions"><button type="button" className="settings-outline" onClick={back} disabled={busy}>Atrás</button><button type="button" className="settings-save" onClick={confirmSimple} disabled={busy}>{busy ? "Registrando…" : "Confirmar registro"}</button></div>
    </>}
  </section>;
}
