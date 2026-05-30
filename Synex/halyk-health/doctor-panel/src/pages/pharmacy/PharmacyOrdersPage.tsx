import { useEffect, useState } from "react";
import { ClipboardList } from "lucide-react";
import type { PharmacyOrder, PharmacyOrderStatus } from "../../api/api";
import { api } from "../../api/api";

type Props = {
  onOpenOrder: (id: string) => void;
};

const STATUS_TABS: { value: string; label: string }[] = [
  { value: "", label: "Все" },
  { value: "NEW", label: "Новые" },
  { value: "CONFIRMED", label: "Подтверждённые" },
  { value: "PREPARING", label: "Собираются" },
  { value: "READY_FOR_PICKUP", label: "Готовы к выдаче" },
  { value: "DELIVERING", label: "Доставляются" },
  { value: "COMPLETED", label: "Завершённые" },
  { value: "CANCELLED", label: "Отменённые" },
  { value: "OUT_OF_STOCK", label: "Нет в наличии" }
];

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

function formatDate(iso: string) {
  return new Date(iso).toLocaleString("ru-KZ", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit"
  });
}

export function PharmacyOrdersPage({ onOpenOrder }: Props) {
  const [orders, setOrders] = useState<PharmacyOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("");

  useEffect(() => {
    setLoading(true);
    api
      .pharmacyOrders(activeTab || undefined)
      .then(setOrders)
      .finally(() => setLoading(false));
  }, [activeTab]);

  const counts: Record<string, number> = {};
  orders.forEach((o) => {
    counts[o.status] = (counts[o.status] || 0) + 1;
  });

  return (
    <div className="content-stack">
      {/* Status tabs */}
      <div className="status-tabs" style={{ flexWrap: "wrap" }}>
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.value}
            id={`order-tab-${tab.value || "all"}`}
            className={activeTab === tab.value ? "active" : ""}
            onClick={() => setActiveTab(tab.value)}
          >
            {tab.label}
            {tab.value && counts[tab.value] ? <span>{counts[tab.value]}</span> : null}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="section-band" style={{ padding: 0 }}>
        {loading ? (
          <div className="ph-loading"><div className="ph-spinner" /></div>
        ) : orders.length === 0 ? (
          <div className="ph-empty">
            <ClipboardList size={32} color="#cfdde2" />
            <span>Заказов нет</span>
          </div>
        ) : (
          <table className="ph-table ph-table-clickable">
            <thead>
              <tr>
                <th>Номер</th>
                <th>Пациент</th>
                <th>Дата</th>
                <th>Доставка</th>
                <th>Товаров</th>
                <th>Сумма</th>
                <th>Статус</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((order) => (
                <tr key={order.id} onClick={() => onOpenOrder(order.id)}>
                  <td>
                    <strong>#{order.id.slice(-6).toUpperCase()}</strong>
                  </td>
                  <td>
                    <strong>{order.patientName}</strong>
                    <span>{order.patientPhone}</span>
                  </td>
                  <td>{formatDate(order.createdAt)}</td>
                  <td>
                    {order.deliveryType === "pickup"
                      ? <span className="status-badge badge-gray">Самовывоз</span>
                      : <span className="status-badge badge-blue">Доставка</span>}
                  </td>
                  <td>{order.items.length}</td>
                  <td><strong>{order.totalPrice.toLocaleString("ru-KZ")} ₸</strong></td>
                  <td>
                    <span className={`status-badge ${ORDER_STATUS_CLASS[order.status] || "badge-gray"}`}>
                      {ORDER_STATUS_LABELS[order.status] || order.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
