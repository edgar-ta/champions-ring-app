"use client";

import { useState, type FormEvent } from "react";

import { PAYMENT_TYPE_LABELS, type IssuingEntity, type PaymentType } from "@/app/core/models/payment";
import { formatCurrency } from "@/app/core/utils/format";
import type { PaymentDetails } from "../models/registration";

const methods = Object.entries(PAYMENT_TYPE_LABELS) as [PaymentType, string][];
const entities: [IssuingEntity, string][] = [["bbva", "BBVA"], ["santander", "Santander"], ["banco-azteca", "Banco Azteca"], ["elektra", "Elektra"], ["other", "Otro"]];

/** Lee los campos de <PaymentMethodFields> del formulario que los contiene. */
export function paymentFromForm(data: FormData): PaymentDetails {
  const type = String(data.get("paymentType")) as PaymentType;
  if (type === "direct-transfer") {
    return { type, referenceId: String(data.get("referenceId")).trim(), issuingEntity: String(data.get("issuingEntity")) as IssuingEntity, issuingEntityName: String(data.get("issuingEntityName") ?? "").trim() };
  }
  if (type === "mercado-pago") return { type, mercadoPagoPaymentId: String(data.get("mercadoPagoPaymentId")).trim() };
  return { type: "cash" };
}

/** Método de pago y sus campos (referencia y banco para transferencia, operación para Mercado Pago). */
export function PaymentMethodFields({ initial, disabled = false }: { initial: PaymentDetails | null; disabled?: boolean }) {
  const [method, setMethod] = useState<PaymentType>(initial?.type ?? "cash");
  const [entity, setEntity] = useState<IssuingEntity>(initial?.type === "direct-transfer" ? initial.issuingEntity : "bbva");
  return <>
    <fieldset className="settings-field visitors-methods" disabled={disabled}>
      <legend className="visitors-label">Método de pago</legend>
      {methods.map(([value, label]) => <label key={value} className={method === value ? "selected" : ""}><input type="radio" name="paymentType" value={value} checked={method === value} onChange={() => setMethod(value)}/>{label}</label>)}
    </fieldset>
    {method === "direct-transfer" && <>
      <div className="settings-field half"><label htmlFor="pay-reference">Número de referencia<span> *</span></label><input id="pay-reference" name="referenceId" required maxLength={60} autoComplete="off" disabled={disabled} defaultValue={initial?.type === "direct-transfer" ? initial.referenceId : ""}/></div>
      <div className="settings-field half"><label htmlFor="pay-entity">Banco emisor<span> *</span></label><select id="pay-entity" name="issuingEntity" value={entity} disabled={disabled} onChange={event => setEntity(event.target.value as IssuingEntity)}>{entities.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></div>
      {entity === "other" && <div className="settings-field"><label htmlFor="pay-entity-name">Nombre del banco<span> *</span></label><input id="pay-entity-name" name="issuingEntityName" required maxLength={80} autoComplete="off" disabled={disabled}/></div>}
    </>}
    {method === "mercado-pago" && <>
      <div className="settings-field"><label htmlFor="pay-mp-id">Número de operación de Mercado Pago<span> *</span></label><input id="pay-mp-id" name="mercadoPagoPaymentId" required inputMode="numeric" pattern="[0-9]+" maxLength={30} autoComplete="off" disabled={disabled} defaultValue={initial?.type === "mercado-pago" ? initial.mercadoPagoPaymentId : ""}/></div>
      <p className="visitors-hint wizard-full">El pago queda pendiente hasta que se confirme con Mercado Pago; mientras tanto la membresía no se activa.</p>
    </>}
  </>;
}

/** Lista de conceptos y total a pagar. */
export function PaymentLines({ lines }: { lines: { label: string; amount: number }[] }) {
  return <>
    <dl className="payment-lines">{lines.map(line => <div key={line.label}><dt>{line.label}</dt><dd>{formatCurrency(line.amount)}</dd></div>)}</dl>
    <p className="visitors-amount">{formatCurrency(lines.reduce((sum, line) => sum + line.amount, 0))}</p>
  </>;
}

/** Paso de pago de una visita. El monto lo calcula el sistema; la recepcionista solo elige el método. */
export function PaymentStep({ lines, initial, onBack, onNext }: {
  lines: { label: string; amount: number }[];
  initial: PaymentDetails | null;
  onBack: () => void;
  onNext: (payment: PaymentDetails) => void;
}) {
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onNext(paymentFromForm(new FormData(event.currentTarget)));
  }

  return <form className="settings-fields" onSubmit={submit}>
    <div className="settings-field"><span className="visitors-label">Monto a pagar</span><PaymentLines lines={lines}/></div>
    <PaymentMethodFields initial={initial}/>
    <div className="visitors-actions"><button type="button" className="settings-outline" onClick={onBack}>Atrás</button><button className="settings-save" type="submit">Continuar</button></div>
  </form>;
}
