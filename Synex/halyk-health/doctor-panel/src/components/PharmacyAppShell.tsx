import {
  Bell,
  Building2,
  ClipboardList,
  LayoutDashboard,
  LogOut,
  Package,
  RefreshCcw,
  Settings,
  ShoppingBag,
  Users
} from "lucide-react";
import type { ReactNode } from "react";
import type { User } from "../api/api";

type PharmacyView =
  | "dashboard"
  | "products"
  | "products-add"
  | `products-edit-${string}`
  | "stock"
  | "orders"
  | `order-${string}`
  | "staff"
  | "profile"
  | "settings";

type Props = {
  user: User;
  view: PharmacyView;
  pharmacyName: string;
  loading?: boolean;
  newOrdersCount: number;
  onViewChange: (view: PharmacyView) => void;
  onRefresh?: () => void;
  onLogout: () => void;
  children: ReactNode;
};

const viewTitles: Partial<Record<string, { eyebrow: string; title: string; description: string }>> = {
  dashboard: {
    eyebrow: "Операционный кабинет",
    title: "Обзор аптеки",
    description: "Сводка заказов, остатков и быстрые действия"
  },
  products: {
    eyebrow: "Управление каталогом",
    title: "Товары",
    description: "Все препараты, цены и остатки аптеки"
  },
  "products-add": {
    eyebrow: "Каталог · Добавление",
    title: "Новый товар",
    description: "Заполните данные препарата для добавления в каталог"
  },
  stock: {
    eyebrow: "Управление остатками",
    title: "Остатки",
    description: "Поступления, списания и история изменений"
  },
  orders: {
    eyebrow: "Входящие заказы",
    title: "Заказы",
    description: "Заказы из Halyk MedCare — подтверждение, сборка, выдача"
  },
  staff: {
    eyebrow: "Управление персоналом",
    title: "Сотрудники",
    description: "Доступы и роли сотрудников аптеки"
  },
  profile: {
    eyebrow: "Настройки организации",
    title: "Профиль аптеки",
    description: "Реквизиты, контакты и способы получения заказов"
  },
  settings: {
    eyebrow: "Кабинет аптеки",
    title: "Настройки",
    description: "Язык, уведомления и безопасность"
  }
};

function resolveTitle(view: string) {
  if (view.startsWith("order-")) {
    return { eyebrow: "Заказы · Подробности", title: "Детали заказа", description: "Статус, состав и действия по заказу" };
  }
  if (view.startsWith("products-edit-")) {
    return { eyebrow: "Каталог · Редактирование", title: "Редактировать товар", description: "Обновите данные препарата" };
  }
  return viewTitles[view] || { eyebrow: "Кабинет аптеки", title: "Страница", description: "" };
}

function isActive(view: string, target: string) {
  if (target === "products") return view === "products" || view === "products-add" || view.startsWith("products-edit-");
  if (target === "orders") return view === "orders" || view.startsWith("order-");
  return view === target;
}

export function PharmacyAppShell({
  user,
  view,
  pharmacyName,
  loading,
  newOrdersCount,
  onViewChange,
  onRefresh,
  onLogout,
  children
}: Props) {
  const title = resolveTitle(view);

  return (
    <div className="app-shell">
      <aside className="sidebar ph-sidebar">
        {/* Brand */}
        <div className="brand">
          <span style={{ background: "#006f63" }}>
            <ShoppingBag size={18} color="#fff" />
          </span>
          <div>
            <strong>Halyk MedCare</strong>
            <small>Кабинет аптеки</small>
          </div>
        </div>

        {/* Pharmacy card */}
        <div className="clinic-card">
          <div className="clinic-card-icon">
            <Building2 size={18} />
          </div>
          <div>
            <strong style={{ fontSize: 13, lineHeight: 1.3 }}>{pharmacyName}</strong>
            <span>Партнёр · Halyk MedCare</span>
          </div>
        </div>

        {/* Nav */}
        <nav className="nav-list">
          <button
            id="nav-dashboard"
            className={isActive(view, "dashboard") ? "active" : ""}
            onClick={() => onViewChange("dashboard")}
          >
            <LayoutDashboard size={18} />
            <span>Обзор</span>
          </button>

          <button
            id="nav-products"
            className={isActive(view, "products") ? "active" : ""}
            onClick={() => onViewChange("products")}
          >
            <Package size={18} />
            <span>Товары</span>
          </button>

          <button
            id="nav-stock"
            className={isActive(view, "stock") ? "active" : ""}
            onClick={() => onViewChange("stock")}
          >
            <RefreshCcw size={18} />
            <span>Остатки</span>
          </button>

          <button
            id="nav-orders"
            className={isActive(view, "orders") ? "active" : ""}
            onClick={() => onViewChange("orders")}
          >
            <ClipboardList size={18} />
            <span>Заказы</span>
            {newOrdersCount > 0 && <small>{newOrdersCount}</small>}
          </button>

          <button
            id="nav-staff"
            className={isActive(view, "staff") ? "active" : ""}
            onClick={() => onViewChange("staff")}
          >
            <Users size={18} />
            <span>Сотрудники</span>
          </button>

          <button
            id="nav-profile"
            className={isActive(view, "profile") ? "active" : ""}
            onClick={() => onViewChange("profile")}
          >
            <Building2 size={18} />
            <span>Профиль аптеки</span>
          </button>

          <button
            id="nav-settings"
            className={isActive(view, "settings") ? "active" : ""}
            onClick={() => onViewChange("settings")}
          >
            <Settings size={18} />
            <span>Настройки</span>
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
            <span className="eyebrow">{title.eyebrow}</span>
            <h1>{title.title}</h1>
            <p>{title.description}</p>
          </div>
          <div className="topbar-actions">
            <button className="icon-button" title="Уведомления" id="btn-notifications">
              <Bell size={18} />
            </button>
            {onRefresh && (
              <button className="secondary-button" onClick={onRefresh} disabled={loading} id="btn-refresh">
                <RefreshCcw size={16} />
                {loading ? "Обновляем..." : "Обновить"}
              </button>
            )}
            <div className="doctor-chip">
              <Building2 size={18} color="#007f6d" />
              <div>
                <strong>{user.fullName}</strong>
                <span>{user.role === "PHARMACY_ADMIN" ? "Администратор" : "Сотрудник"}</span>
              </div>
            </div>
          </div>
        </header>
        {children}
      </main>
    </div>
  );
}

export type { PharmacyView };
