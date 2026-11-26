"use client";

import { useEffect, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";

import { firebaseReceptionistRepository as repository, loginErrorMessage, passwordResetErrorMessage } from "../repositories/firebase-receptionist-repository";

type Mode = "login" | "recovery" | "sent";

export function LoginForm() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState("");
  const [notice, setNotice] = useState("");

  const [redirecting, setRedirecting] = useState(false);
  const [checking, setChecking] = useState(true);
  const [busy, setBusy] = useState(false);

  useEffect(() => repository.observeSession(
    (profile) => {
      if (profile) { setRedirecting(true); router.replace("/inicio"); }
      setChecking(false);
    },
    (error) => { setNotice(loginErrorMessage(error)); setChecking(false); },
  ), [router]);

  function switchTo(next: Mode) { setMode(next); setNotice(""); }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    const data = new FormData(event.currentTarget);
    setBusy(true);
    setNotice("");
    try {
      await repository.login(email, String(data.get("password")), data.get("remember") === "on");
    } catch (error) {
      setNotice(loginErrorMessage(error));
    } finally { setBusy(false); }
  }

  async function handleRecovery(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    setBusy(true);
    setNotice("");
    try {
      await repository.sendPasswordReset(email);
      setMode("sent");
    } catch (error) {
      const message = passwordResetErrorMessage(error);
      // Un correo no registrado se trata como enviado, para no revelar qué cuentas existen.
      if (message) setNotice(message); else setMode("sent");
    } finally { setBusy(false); }
  }

  if (checking || redirecting) return <p role="status">{redirecting ? "Abriendo panel de recepción…" : "Verificando sesión…"}</p>;

  if (mode === "sent") return (
    <div className="login-form recovery-sent" role="status">
      <span className="recovery-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18v12H3ZM3 7l9 6 9-6"/></svg></span>
      <h2>Revisa tu correo</h2>
      <p>Si <strong>{email.trim()}</strong> tiene una cuenta, te enviamos un enlace para crear una nueva contraseña. Puede tardar unos minutos; revisa también la carpeta de spam.</p>
      <button className="login-button" type="button" onClick={() => switchTo("login")}>Volver a iniciar sesión</button>
      <button className="recovery-link" type="button" onClick={() => switchTo("recovery")}>¿No te llegó? Enviar de nuevo</button>
    </div>
  );

  if (mode === "recovery") return (
    <form className="login-form" onSubmit={handleRecovery} aria-busy={busy}>
      <div className="recovery-intro">
        <h2>Recuperar contraseña</h2>
        <p>Escribe el correo con el que inicias sesión y te enviaremos un enlace para crear una nueva contraseña.</p>
      </div>
      <div className="form-field">
        <label htmlFor="recovery-email">Correo electrónico <span aria-hidden="true">*</span></label>
        <input id="recovery-email" type="email" autoComplete="username" placeholder="ejemplo@championsring.com" required autoFocus disabled={busy} value={email} onChange={event => setEmail(event.target.value)} />
      </div>
      <button className="login-button" type="submit" disabled={busy}>{busy ? "Enviando…" : "Enviar enlace"}</button>
      <button className="recovery-link" type="button" onClick={() => switchTo("login")} disabled={busy}>← Volver a iniciar sesión</button>
      <p className="form-notice" role="status" aria-live="polite">{notice}</p>
    </form>
  );

  return (
    <form className="login-form" onSubmit={handleSubmit} aria-busy={busy}>
      <div className="form-field">
        <label htmlFor="identifier">Correo electrónico <span aria-hidden="true">*</span></label>
        <input id="identifier" name="identifier" type="email" autoComplete="username" placeholder="ejemplo@championsring.com" required disabled={busy} value={email} onChange={event => setEmail(event.target.value)} />
      </div>
      <div className="form-field">
        <label htmlFor="password">Contraseña <span aria-hidden="true">*</span></label>
        <input id="password" name="password" type="password" autoComplete="current-password" placeholder="••••••••" required disabled={busy} />
      </div>
      <div className="login-options">
        <label className="remember-option" htmlFor="remember">
          <input id="remember" name="remember" type="checkbox" disabled={busy} />
          <span>Recordarme</span>
        </label>
        <button className="recovery-button" type="button" onClick={() => switchTo("recovery")} disabled={busy}>
          ¿Olvidaste tu contraseña?
        </button>
      </div>
      <button className="login-button" type="submit" disabled={busy}>{busy ? "Iniciando sesión…" : "Iniciar sesión"}</button>
      <p className="form-notice" role="status" aria-live="polite">{notice}</p>
    </form>
  );
}
