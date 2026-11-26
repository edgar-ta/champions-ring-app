"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";

import { initials } from "../core/utils/format";
import { useReceptionist } from "../features/authentication/components/receptionist-session";
import { firebaseReceptionistRepository } from "../features/authentication/repositories/firebase-receptionist-repository";

/** Secciones del menú. Las que no tienen `href` todavía no existen y solo muestran un aviso. */
const navigation: { label: string; href?: string; icon: string }[] = [
  { label: "Inicio", href: "/inicio", icon: "M3 10 12 3l9 7v11h-6v-7H9v7H3Z" },
  { label: "Alumnos", href: "/alumnos", icon: "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M17 4a4 4 0 0 1 0 8M22 21v-2a4 4 0 0 0-3-4" },
  { label: "Membresías", href: "/membresias", icon: "M3 3h18v18H3ZM7 7h10v6H7ZM7 17h4m3 0h3" },
  { label: "Pagos", icon: "M3 3h18v18H3ZM3 9h18" },
  { label: "Inventario", icon: "M3 6c0-4 18-4 18 0v12c0 4-18 4-18 0ZM3 6c0 4 18 4 18 0M3 12c0 4 18 4 18 0" },
  { label: "Ventas", icon: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18ZM8 8l8 8m0-8-8 8" },
  { label: "Documentos", href: "/documentos", icon: "M4 3h11l5 5v13H4ZM14 3v6h6M8 13h8m-8 4h8" },
  { label: "Reportes", icon: "M4 3v18h17M8 6h8m-8 5h12M8 16h9" },
  { label: "Configuración", href: "/configuracion", icon: "M9 3h6l1 3 3 1 2 5-2 5-3 1-1 3H9l-1-3-3-1-2-5 2-5 3-1ZM12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8" },
];

function Icon({ path }: { path: string }) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={path} /></svg>;
}

export function DashboardSidebar({ onNotice }: { onNotice: (message: string) => void }) {
  const pathname = usePathname();
  const receptionist = useReceptionist();
  const fullName = `${receptionist.name} ${receptionist.lastName}`.trim();
  const [busy, setBusy] = useState(false);
  async function logout() {
    setBusy(true);
    try {
      // <ReceptionistGate> detecta la sesión cerrada y regresa al inicio de sesión.
      await firebaseReceptionistRepository.logout();
    } catch { onNotice("No se pudo cerrar la sesión. Inténtalo de nuevo."); setBusy(false); }
  }

  return (
    <aside className="settings-sidebar" aria-label="Menú principal">
      <Link href="/inicio" className="settings-brand"><span className="settings-logo"><svg viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><g transform="rotate(-45 16 16)"><path d="M10 16h12M3 13v6m26-6v6"/><rect x="5" y="8" width="5" height="16" rx="1"/><rect x="22" y="8" width="5" height="16" rx="1"/></g></svg></span><span><strong>CHAMPIONS RING</strong><small>GYM SYSTEM</small></span></Link>
      <nav>{navigation.map(({ label, href, icon }) => {
        // /alumnos/registrar también marca "Alumnos".
        const active = !!href && (pathname === href || pathname.startsWith(`${href}/`));
        return href
          ? <Link key={label} href={href} className={`settings-nav-item ${active ? "active" : ""}`} aria-current={active ? "page" : undefined}><Icon path={icon}/>{label}</Link>
          : <button key={label} type="button" className="settings-nav-item" onClick={() => onNotice(`La sección ${label} aún no está disponible.`)}><Icon path={icon}/>{label}</button>;
      })}</nav>
      <div className="settings-profile"><span className="settings-avatar" aria-hidden="true">{initials(fullName)}</span><span><strong>{fullName}</strong><small>Recepcionista</small></span><button type="button" aria-label="Cerrar sesión" title="Cerrar sesión" disabled={busy} onClick={logout}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M10 4H4v16h6m4-13 5 5-5 5m-6-5h11"/></svg></button></div>
    </aside>
  );
}
