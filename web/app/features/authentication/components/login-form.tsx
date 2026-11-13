"use client";

import { useEffect, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";

import { firebaseReceptionistRepository as repository, loginErrorMessage } from "../repositories/firebase-receptionist-repository";

export function LoginForm() {
  const router = useRouter();
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

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    const data = new FormData(event.currentTarget);
    setBusy(true);
    setNotice("");
    try {
      await repository.login(String(data.get("identifier")), String(data.get("password")), data.get("remember") === "on");
    } catch (error) {
      setNotice(loginErrorMessage(error));
    } finally { setBusy(false); }
  }

  if (checking || redirecting) return <p role="status">{redirecting ? "Abriendo panel de recepción…" : "Verificando sesión…"}</p>;

  return (
    <form className="login-form" onSubmit={handleSubmit} aria-busy={busy}>
      <div className="form-field">
        <label htmlFor="identifier">Correo electrónico <span aria-hidden="true">*</span></label>
        <input id="identifier" name="identifier" type="email" autoComplete="username" placeholder="ejemplo@championsring.com" required disabled={busy} />
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
        <button className="recovery-button" type="button" onClick={() => setNotice("Para recuperar tu contraseña, comunícate con la recepción del gimnasio.")}>
          ¿Olvidaste tu contraseña?
        </button>
      </div>
      <button className="login-button" type="submit" disabled={busy}>{busy ? "Iniciando sesión…" : "Iniciar sesión"}</button>
      <p className="form-notice" role="status" aria-live="polite">{notice}</p>
    </form>
  );
}
