import type { Timestamp } from "firebase/firestore";

const dateFormatter = new Intl.DateTimeFormat("es-MX", { day: "2-digit", month: "short", year: "numeric" });
const timeFormatter = new Intl.DateTimeFormat("es-MX", { hour: "2-digit", minute: "2-digit" });
const currencyFormatter = new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" });

export const formatDate = (value: Date) => dateFormatter.format(value);
export const formatTime = (value: Date) => timeFormatter.format(value);
export const formatCurrency = (value: number) => currencyFormatter.format(value);

/** Firestore puede devolver documentos sin un campo de fecha: lo convierte con cuidado. */
export function toDate(value: Timestamp | null | undefined): Date | null {
  return value && typeof value.toDate === "function" ? value.toDate() : null;
}

/** Años cumplidos a la fecha actual. */
export function ageOn(birthDate: Date, today = new Date()): number {
  let age = today.getFullYear() - birthDate.getFullYear();
  if (today.getMonth() < birthDate.getMonth() || (today.getMonth() === birthDate.getMonth() && today.getDate() < birthDate.getDate())) age--;
  return age;
}

export function startOfToday(): Date {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return today;
}

export function initials(fullName: string): string {
  return fullName.split(" ").filter(Boolean).slice(0, 2).map(part => part[0]).join("").toUpperCase();
}
