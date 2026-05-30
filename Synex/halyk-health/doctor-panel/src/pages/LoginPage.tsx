import { FormEvent, useState } from "react";
import { LogIn, ShieldCheck } from "lucide-react";

type LoginPageProps = {
  onLogin: (email: string, password: string) => Promise<void>;
};

export function LoginPage({ onLogin }: LoginPageProps) {
  const [email, setEmail] = useState("doctor@test.kz");
  const [password, setPassword] = useState("123456");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      await onLogin(email, password);
    } catch (loginError) {
      setError(loginError instanceof Error ? loginError.message : "Не удалось войти");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="login-screen">
      <section className="login-panel">
        <div className="login-brand">
          <span>HH</span>
          <div>
            <h1>Halyk Health</h1>
            <p>Doctor Panel</p>
          </div>
        </div>

        <form className="form" onSubmit={handleSubmit}>
          <label>
            Email
            <input value={email} onChange={(event) => setEmail(event.target.value)} type="email" />
          </label>
          <label>
            Пароль
            <input value={password} onChange={(event) => setPassword(event.target.value)} type="password" />
          </label>
          {error && <div className="error-text">{error}</div>}
          <button className="primary-button" disabled={loading}>
            <LogIn size={18} />
            {loading ? "Вход..." : "Войти"}
          </button>
        </form>

        <div className="security-note">
          <ShieldCheck size={18} />
          <span>ИИ-агент не заменяет врача. Он объясняет назначение, созданное врачом.</span>
        </div>
      </section>
    </main>
  );
}

