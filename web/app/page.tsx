import { LoginForm } from "./features/authentication/components/login-form";

export default function Home() {
  return (
    <main className="login-page">
      <section className="login-card" aria-labelledby="login-title">
        <div className="brand" aria-label="Champions Ring Gym System">
          <span className="brand-icon" aria-hidden="true">
            <svg viewBox="0 0 32 32" fill="none">
              <g transform="rotate(-45 16 16)" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M11 16h10M4 13H2v6h2m24-6h2v6h-2" />
                <rect x="4" y="9" width="4" height="14" rx="1" />
                <rect x="8" y="12" width="3" height="8" rx=".7" />
                <rect x="24" y="9" width="4" height="14" rx="1" />
                <rect x="21" y="12" width="3" height="8" rx=".7" />
              </g>
            </svg>
          </span>
          <div className="brand-copy">
            <span className="brand-name">CHAMPIONS RING</span>
            <span className="brand-subtitle">GYM SYSTEM</span>
          </div>
        </div>
        <header className="login-heading">
          <h1 id="login-title">Bienvenido de nuevo</h1>
          <p>Ingresa tus credenciales para acceder al sistema</p>
        </header>
        <LoginForm />
      </section>
    </main>
  );
}
