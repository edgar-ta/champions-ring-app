"use client";

import { DashboardSidebar } from "../components/dashboard-sidebar";
import { useEffect, useState, type FormEvent } from "react";

const initial = { name: "Jose Hernandez", address: "Av. Rebeldes de la Revolución 402, Col. San Ángel", phone: "55-1234-5678", email: "contacto@championsring.com", hours: "Lunes a Viernes: 6:00 AM - 10:00 PM", emailNotifications: true, overdueAlerts: true, dailySummary: false };
type Settings = typeof initial;
const storageKey = "champions-ring-settings-v1";

export function SettingsScreen() {
  const [settings, setSettings] = useState<Settings>(initial);
  const [notice, setNotice] = useState("");
  const [ready, setReady] = useState(false);
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    try {
      const saved = JSON.parse(localStorage.getItem(storageKey) || "null");
      if (saved && typeof saved === "object") {
        setSettings(Object.fromEntries(Object.entries(initial).map(([key, value]) => [key, typeof saved[key] === typeof value ? saved[key] : value])) as Settings);
      }
    } catch { setNotice("No se pudieron cargar los ajustes guardados."); }
    setReady(true);
  }, []);

  function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try { localStorage.setItem(storageKey, JSON.stringify(settings)); setNotice("Cambios guardados en este navegador."); }
    catch { setNotice("No se pudieron guardar los cambios. Revisa el almacenamiento del navegador."); }
  }

  async function resetPassword() {
    setBusy(true);
    try {
      const [{ auth }, { sendPasswordResetEmail }] = await Promise.all([import("../core/firebase/firebase"), import("firebase/auth")]);
      if (!auth.currentUser?.email) { setNotice("Inicia sesión para solicitar el cambio de contraseña."); return; }
      await sendPasswordResetEmail(auth, auth.currentUser.email);
      setNotice("Enviamos un enlace para cambiar tu contraseña al correo de tu cuenta.");
    } catch { setNotice("No se pudo enviar el correo de cambio de contraseña. Inténtalo de nuevo."); }
    finally { setBusy(false); }
  }

  return <div className="settings-app">
    <DashboardSidebar active={9} onNotice={setNotice}/>
    <form className="settings-main" onSubmit={save}>
      <header className="settings-header"><div><h1>Configuración</h1><p>Ajustes generales del sistema y preferencias del gimnasio.</p></div><button className="settings-save" disabled={!ready} type="submit">Guardar cambios</button></header>
      <div className="settings-content">
        {notice && <div className="settings-notice" role="status" aria-live="polite">{notice}<button type="button" aria-label="Descartar mensaje" onClick={() => setNotice("")}>×</button></div>}
        <div className="settings-grid">
          <section className="settings-panel"><h2>Información del Usuario</h2><div className="settings-fields">
            {([["name", "Nombre del Recepcionista", "text", true], ["address", "Dirección", "text", true], ["phone", "Teléfono", "tel", true], ["email", "Correo de contacto", "email", true], ["hours", "Horario de operación", "text", false]] as const).map(([key, label, type, required]) => <div key={key} className={`settings-field ${key === "phone" || key === "email" ? "half" : ""}`}><label htmlFor={`settings-${key}`}>{label}{required && <span> *</span>}</label><input id={`settings-${key}`} type={type} required={required} value={settings[key]} onChange={event => setSettings({ ...settings, [key]: event.target.value })}/></div>)}
          </div></section>
          <div className="settings-right"><section className="settings-panel"><h2>Notificaciones</h2>
            {([["emailNotifications", "Notificaciones por email", "Enviar alertas y recibos automáticamente a los alumnos."], ["overdueAlerts", "Alertas de pagos vencidos", "Notificar de inmediato a administración sobre accesos denegados por adeudo."], ["dailySummary", "Resumen diario", "Recibir un reporte matutino con la asistencia y ventas del día anterior."]] as const).map(([key, title, description]) => <div className="settings-notification" key={key}><div><label htmlFor={key}>{title}</label><p id={`${key}-description`}>{description}</p></div><input className="settings-switch" id={key} type="checkbox" role="switch" aria-describedby={`${key}-description`} checked={settings[key]} onChange={event => setSettings({ ...settings, [key]: event.target.checked })}/></div>)}
          </section><section className="settings-panel settings-security"><h2>Seguridad y Accesos</h2><div className="settings-password"><p>Contraseña del sistema</p><button type="button" className="settings-outline" disabled={busy} onClick={resetPassword}>{busy ? "Procesando…" : "Cambiar contraseña"}</button></div><div className="settings-session"><h3>Sesión activa actual</h3><p>Administración desde este navegador</p><button type="button" className="settings-danger" onClick={() => setNotice("El cierre de otras sesiones requiere una función de administración en el servidor; todavía no está disponible.")}>Cerrar todas las demás sesiones</button></div></section></div>
        </div>
      </div>
    </form>
  </div>;
}
