import { useEffect, useState } from "react";
import { AlertCircle, ClipboardList, Package, PackagePlus, ShoppingBag, Truck } from "lucide-react";
import type { PharmacyDashboard, PharmacyOrder } from "../../api/api";
import { api } from "../../api/api";

type Props = {
  onNavigate: (view: string) => void;
};

const ORDER_STATUS_LABELS: Record<string, string> = {
  NEW: "Новый",
  CONFIRMED: "Подтверждён",
  PREPARING: "Собирается",
  READY_FOR_PICKUP: "Готов к выдаче",
  DELIVERING: "Доставляется",
  COMPLETED: "Завершён",
  CANCELLED: "Отменён",
  OUT_OF_STOCK: "Нет в наличии"
};

const ORDER_STATUS_CLASS: Record<string, string> = {
  NEW: "badge-blue",
  CONFIRMED: "badge-green",
  PREPARING: "badge-amber",
  READY_FOR_PICKUP: "badge-green",
  DELIVERING: "badge-blue",
  COMPLETED: "badge-gray",
  CANCELLED: "badge-red",
  OUT_OF_STOCK: "badge-red"
};

function formatPrice(price: number) {
  return price.toLocaleString("ru-KZ") + " ₸";
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleString("ru-KZ", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" });
}

export function PharmacyDashboardPage({ onNavigate }: Props) {
  const [data, setData] = useState<PharmacyDashboard | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    setLoading(true);
    api
      .pharmacyDashboard()
      .then(setData)
      .catch(() => setError("Не удалось загрузить данные"))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="ph-loading">
        <div className="ph-spinner" />
        <span>Загрузка панели...</span>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="ph-error">
        <AlertCircle size={20} />
        <span>{error || "Нет данных"}</span>
      </div>
    );
  }

  const { stats, recentOrders, pharmacy } = data;

  return (
    <div className="content-stack">
      {/* Welcome */}
      <div className="ph-welcome-card">
        <div className="ph-welcome-icon">
          <ShoppingBag size={22} />
        </div>
        <div>
          <strong>{pharmacy.name}</strong>
          <span>{pharmacy.address}</span>
        </div>
        <div className="ph-welcome-badges">
          {pharmacy.pickupEnabled && <span className="ph-tag ph-tag-green">Самовывоз</span>}
          {pharmacy.deliveryEnabled && <span className="ph-tag ph-tag-blue">Доставка</span>}
        </div>
      </div>

      {/* Stats */}
      <div className="stats-grid">
        <div className="stat-card blue">
          <div className="stat-card-top">
            <span>Новые заказы</span>
            <div className="stat-icon">
              <ClipboardList size={20} />
            </div>
          </div>
          <strong>{stats.newOrders}</strong>
          <small>Ожидают обработки</small>
        </div>
        <div className="stat-card amber">
          <div className="stat-card-top">
            <span>В обработке</span>
            <div className="stat-icon">
              <Package size={20} />
            </div>
          </div>
          <strong>{stats.processingOrders}</strong>
          <small>Подтверждены и собираются</small>
        </div>
        <div className="stat-card red">
          <div className="stat-card-top">
            <span>Мало остатков</span>
            <div className="stat-icon">
              <AlertCircle size={20} />
            </div>
          </div>
          <strong>{stats.lowStockProducts}</strong>
          <small>Товаров с низким запасом</small>
        </div>
        <div className="stat-card green">
          <div className="stat-card-top">
            <span>Всего товаров</span>
            <div className="stat-icon">
              <PackagePlus size={20} />
            </div>
          </div>
          <strong>{stats.totalProducts}</strong>
          <small>В каталоге аптеки</small>
        </div>
      </div>

      {/* Quick actions */}
      <div className="ph-quick-actions">
        <h2 className="ph-section-title">Быстрые действия</h2>
        <div className="ph-action-buttons">
          <button className="ph-action-btn ph-action-btn-primary" id="btn-add-product" onClick={() => onNavigate("products-add")}>
            <PackagePlus size={18} />
            Добавить товар
          </button>
          <button className="ph-action-btn ph-action-btn-secondary" id="btn-open-orders" onClick={() => onNavigate("orders")}>
            <ClipboardList size={18} />
            Открыть заказы
            {stats.newOrders > 0 && <span className="ph-badge-count">{stats.newOrders}</span>}
          </button>
          <button className="ph-action-btn ph-action-btn-secondary" id="btn-update-stock" onClick={() => onNavigate("stock")}>
            <Package size={18} />
            Обновить остатки
          </button>
        </div>
      </div>

      {/* Recent orders */}
      <div className="section-band">
        <div className="section-header">
          <div>
            <h2>Последние заказы</h2>
            <p>5 самых новых заказов</p>
          </div>
          <button className="secondary-button" onClick={() => onNavigate("orders")}>
            <Truck size={16} />
            Все заказы
          </button>
        </div>

        {recentOrders.length === 0 ? (
          <div className="ph-empty">Заказов пока нет</div>
        ) : (
          <div className="ph-order-list">
            {recentOrders.map((order: PharmacyOrder) => (
              <div key={order.id} className="ph-order-row" onClick={() => onNavigate(`order-${order.id}`)}>
                <div className="ph-order-row-left">
                  <strong className="ph-order-id">#{order.id.slice(-6).toUpperCase()}</strong>
                  <div className="ph-order-meta">
                    <span>{order.patientName}</span>
                    <span>·</span>
                    <span>{formatDate(order.createdAt)}</span>
                    <span>·</span>
                    <span>{order.deliveryType === "pickup" ? "Самовывоз" : "Доставка"}</span>
                  </div>
                </div>
                <div className="ph-order-row-right">
                  <strong>{formatPrice(order.totalPrice)}</strong>
                  <span className={`status-badge ${ORDER_STATUS_CLASS[order.status] || "badge-gray"}`}>
                    {ORDER_STATUS_LABELS[order.status] || order.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
