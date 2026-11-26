"use client";

import { useState, type ReactNode } from "react";
import { DashboardSidebar } from "./dashboard-sidebar";

/**
 * Barra lateral, encabezado y aviso descartable comunes a las pantallas del panel.
 * `action` va a la derecha del encabezado; `wide` quita el ancho máximo del contenido.
 */
export function PanelShell({ title, description, action, wide = false, children }: {
  title: string;
  description: string;
  action?: ReactNode;
  wide?: boolean;
  children: ReactNode;
}) {
  const [notice, setNotice] = useState("");
  return <div className="settings-app">
    <DashboardSidebar onNotice={setNotice}/>
    <main className="settings-main">
      <header className="settings-header"><div><h1>{title}</h1><p>{description}</p></div>{action}</header>
      <div className={`settings-content ${wide ? "panel-content-wide" : "panel-content"}`}>
        {notice && <div className="settings-notice" role="status" aria-live="polite">{notice}<button type="button" aria-label="Descartar mensaje" onClick={() => setNotice("")}>×</button></div>}
        {children}
      </div>
    </main>
  </div>;
}
