import {
  Activity,
  BarChart3,
  Bell,
  CalendarClock,
  FileText,
  LayoutDashboard,
  LogOut,
  RefreshCcw,
  ShieldCheck,
  Stethoscope
} from "lucide-react";
import type { ReactNode } from "react";
import type { User } from "../api/api";

type View = "dashboard" | "appointments" | "prescriptions" | "demand";

type AppShellProps = {
  user: User;
  view: View;
  loading: boolean;
  pendingCount: number;
  todayCount: number;
  prescriptionsCount: number;
  onViewChange: (view: View) => void;
  onRefresh: () => void;
  onLogout: () => void;
  children: ReactNode;
};

const viewTitles: Record<View, { eyebrow: string; title: string; description: string }> = {
  dashboard: {
    eyebrow: "CRM-пульт",
    title: "Рабочий день врача",
    description: "Заявки, пациенты и назначения в одном кабинете"
  },
  appointments: {
    eyebrow: "Очередь пациентов",
    title: "Заявки на приём",
    description: "Фильтрация, статусы, быстрые действия и карточка пациента"
  },
  prescriptions: {
    eyebrow: "Медицинские документы",
    title: "Цифровые назначения",
    description: "История назначений, AI-анализ и список препаратов"
  },
  demand: {
    eyebrow: "Рыночная аналитика",
    title: "Отчет спроса B2B",
    description: "AI-анализ популярных препаратов, дефицита и рыночных трендов"
  }
};

export function AppShell({
  user,
  view,
  loading,
  pendingCount,
  todayCount,
  prescriptionsCount,
  onViewChange,
  onRefresh,
  onLogout,
  children
}: AppShellProps) {
  const title = viewTitles[view];

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <span>HH</span>
          <div>
            <strong>Halyk Health</strong>
            <small>Doctor Panel</small>
          </div>
        </div>

        <div className="clinic-card">
          <div className="clinic-card-icon">
            <Stethoscope size={18} />
          </div>
          <div>
            <strong>Поликлиника №5</strong>
            <span>Алматы · кабинет врача</span>
          </div>
        </div>

        <nav className="nav-list">
          <button className={view === "dashboard" ? "active" : ""} onClick={() => onViewChange("dashboard")}>
            <LayoutDashboard size={18} />
            <span>Дашборд</span>
          </button>
          <button className={view === "appointments" ? "active" : ""} onClick={() => onViewChange("appointments")}>
            <CalendarClock size={18} />
            <span>Заявки</span>
            {pendingCount > 0 && <small>{pendingCount}</small>}
          </button>
          <button className={view === "prescriptions" ? "active" : ""} onClick={() => onViewChange("prescriptions")}>
            <FileText size={18} />
            <span>Назначения</span>
            {prescriptionsCount > 0 && <small>{prescriptionsCount}</small>}
          </button>
          <button className={view === "demand" ? "active" : ""} onClick={() => onViewChange("demand")}>
            <BarChart3 size={18} />
            <span>Аналитика B2B</span>
          </button>
        </nav>

        <div className="sidebar-summary">
          <div>
            <span>Сегодня</span>
            <strong>{todayCount}</strong>
          </div>
          <div>
            <span>Новые</span>
            <strong>{pendingCount}</strong>
          </div>
        </div>

        <div className="ai-safety-card">
          <ShieldCheck size={18} />
          <span>ИИ объясняет назначение врача и не заменяет медицинскую консультацию.</span>
        </div>

        <button className="ghost-button" onClick={onLogout}>
          <LogOut size={18} />
          Выйти
        </button>
      </aside>

      <main className="main-panel">
        <header className="topbar">
          <div>
            <span className="eyebrow">{title.eyebrow}</span>
            <h1>{title.title}</h1>
            <p>{title.description}</p>
          </div>
          <div className="topbar-actions">
            <button className="icon-button" title="Уведомления">
              <Bell size={18} />
            </button>
            <button className="secondary-button" onClick={onRefresh} disabled={loading}>
              <RefreshCcw size={18} />
              {loading ? "Обновляем..." : "Обновить"}
            </button>
            <div className="doctor-chip">
              <Activity size={18} />
              <div>
                <strong>{user.fullName}</strong>
                <span>{user.email}</span>
              </div>
            </div>
          </div>
        </header>
        {children}
      </main>
    </div>
  );
}
