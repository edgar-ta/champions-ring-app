"use client";

import Link from "next/link";
import { useState } from "react";

const navigation = ["Inicio", "Alumnos", "Membresías", "Pagos", "Inventario", "Ventas", "Documentos", "Responsivas", "Reportes", "Configuración"];
const paths = ["M3 10 12 3l9 7v11h-6v-7H9v7H3Z", "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M17 4a4 4 0 0 1 0 8M22 21v-2a4 4 0 0 0-3-4", "M3 3h18v18H3ZM7 7h10v6H7ZM7 17h4m3 0h3", "M3 3h18v18H3ZM3 9h18", "M3 6c0-4 18-4 18 0v12c0 4-18 4-18 0ZM3 6c0 4 18 4 18 0M3 12c0 4 18 4 18 0", "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18ZM8 8l8 8m0-8-8 8", "M4 3h11l5 5v13H4ZM14 3v6h6M8 13h8m-8 4h8", "M4 3h10l4 4v4M4 3v18h14M8 17l2-5 8-8 3 3-8 8Z", "M4 3v18h17M8 6h8m-8 5h12M8 16h9", "M9 3h6l1 3 3 1 2 5-2 5-3 1-1 3H9l-1-3-3-1-2-5 2-5 3-1ZM12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8"];
function Icon({ index }: { index: number }) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={paths[index]} /></svg>;
}

export function DashboardSidebar({ active, onNotice }: { active: 0 | 1 | 9; onNotice: (message: string) => void }) {
  const [busy, setBusy] = useState(false);
  async function logout() {
    setBusy(true);
    try {
      const [{ auth }, { signOut }] = await Promise.all([import("../core/firebase/firebase"), import("firebase/auth")]);
      await signOut(auth);
      window.location.assign("/");
    } catch { onNotice("No se pudo cerrar la sesión. Inténtalo de nuevo."); setBusy(false); }
  }

  return (
    <aside className="settings-sidebar" aria-label="Menú principal">
      <Link href="/inicio" className="settings-brand"><span className="settings-logo"><svg viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><g transform="rotate(-45 16 16)"><path d="M10 16h12M3 13v6m26-6v6"/><rect x="5" y="8" width="5" height="16" rx="1"/><rect x="22" y="8" width="5" height="16" rx="1"/></g></svg></span><span><strong>CHAMPIONS RING</strong><small>GYM SYSTEM</small></span></Link>
      <nav>{navigation.map((label, index) => {
        const href = index === 0 ? "/inicio" : index === 1 ? "/alumnos" : index === 9 ? "/configuracion" : null;
        return href ? <Link key={label} href={href} className={`settings-nav-item ${active === index ? "active" : ""}`} aria-current={active === index ? "page" : undefined}><Icon index={index}/>{label}</Link> : <button key={label} type="button" className="settings-nav-item" onClick={() => onNotice(`La sección ${label} aún no está disponible.`)}><Icon index={index}/>{label}</button>;
      })}</nav>
      <div className="settings-profile"><span className="settings-avatar" aria-hidden="true">SG</span><span><strong>Sofía Gómez</strong><small>Recepcionista</small></span><button type="button" aria-label="Cerrar sesión" title="Cerrar sesión" disabled={busy} onClick={logout}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M10 4H4v16h6m4-13 5 5-5 5m-6-5h11"/></svg></button></div>
    </aside>
  );
}
