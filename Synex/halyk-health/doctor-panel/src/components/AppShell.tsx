import { CalendarClock, ClipboardPlus, FileText, LayoutDashboard, LogOut } from "lucide-react";
import type { ReactNode } from "react";
import type { User } from "../api/api";

type View = "dashboard" | "appointments" | "prescriptions";

type AppShellProps = {
  user: User;
  view: View;
  onViewChange: (view: View) => void;
  onLogout: () => void;
  children: ReactNode;
};

export function AppShell({ user, view, onViewChange, onLogout, children }: AppShellProps) {
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

        <nav className="nav-list">
          <button className={view === "dashboard" ? "active" : ""} onClick={() => onViewChange("dashboard")}>
            <LayoutDashboard size={18} />
            Дашборд
          </button>
          <button className={view === "appointments" ? "active" : ""} onClick={() => onViewChange("appointments")}>
            <CalendarClock size={18} />
            Заявки
          </button>
          <button className={view === "prescriptions" ? "active" : ""} onClick={() => onViewChange("prescriptions")}>
            <FileText size={18} />
            Назначения
          </button>
        </nav>

        <button className="ghost-button" onClick={onLogout}>
          <LogOut size={18} />
          Выйти
        </button>
      </aside>

      <main className="main-panel">
        <header className="topbar">
          <div>
            <span className="eyebrow">Кабинет врача</span>
            <h1>{user.fullName}</h1>
          </div>
          <div className="doctor-chip">
            <ClipboardPlus size={18} />
            <span>{user.email}</span>
          </div>
        </header>
        {children}
      </main>
    </div>
  );
}
