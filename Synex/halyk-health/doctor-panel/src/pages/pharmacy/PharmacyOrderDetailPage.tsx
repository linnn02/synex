import { useEffect, useState } from "react";
import { AlertTriangle, ArrowLeft, CheckCircle, Package, XCircle } from "lucide-react";
import type { PharmacyOrder, PharmacyOrderStatus, PharmacyProduct } from "../../api/api";
import { api } from "../../api/api";

type Props = {
  orderId: string;
  onBack: () => void;
};

const STATUS_LABELS: Record<string, string> = {
  NEW: "Новый",
  CONFIRMED: "Подтверждён",
  PREPARING: "Собирается",
  READY_FOR_PICKUP: "Готов к выдаче",
  DELIVERING: "Доставляется",
  COMPLETED: "Завершён",
  CANCELLED: "Отменён",
  OUT_OF_STOCK: "Нет в наличии"
};

const STATUS_CLASS: Record<string, string> = {
  NEW: "badge-blue",
  CONFIRMED: "badge-green",
  PREPARING: "badge-amber",
  READY_FOR_PICKUP: "badge-green",
  DELIVERING: "badge-blue",
  COMPLETED: "badge-gray",
  CANCELLED: "badge-red",
  OUT_OF_STOCK: "badge-red"
};

type StatusTransition = { label: string; next: PharmacyOrderStatus; style: string };

function getTransitions(status: string): StatusTransition[] {
  switch (status) {
    case "NEW":
      return [
        { label: "Подтвердить заказ", next: "CONFIRMED", style: "primary-button" },
        { label: "Отменить", next: "CANCELLED", style: "ph-danger-button" },
        { label: "Нет в наличии", next: "OUT_OF_STOCK", style: "secondary-button" }
      ];
    case "CONFIRMED":
      return [
        { label: "Начать сборку", next: "PREPARING", style: "primary-button" },
        { label: "Отменить", next: "CANCELLED", style: "ph-danger-button" }
      ];
    case "PREPARING":
      return [
        { label: "Готов к выдаче", next: "READY_FOR_PICKUP", style: "primary-button" },
        { label: "Передан в доставку", next: "DELIVERING", style: "primary-button" }
      ];
    case "READY_FOR_PICKUP":
      return [{ label: "Завершить", next: "COMPLETED", style: "primary-button" }];
    case "DELIVERING":
      return [{ label: "Завершить", next: "COMPLETED", style: "primary-button" }];
    default:
      return [];
  }
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleString("ru-KZ", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}

export function PharmacyOrderDetailPage({ orderId, onBack }: Props) {
  const [order, setOrder] = useState<PharmacyOrder | null>(null);
  const [alternatives, setAlternatives] = useState<Record<string, PharmacyProduct[]>>({});
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState("");

  async function load() {
    setLoading(true);
    try {
      const data = await api.pharmacyOrder(orderId);
      setOrder(data);
      const hasUnavailable = data.items.some((i) => !i.isAvailable);
      if (hasUnavailable) {
        const alts = await api.orderAlternatives(orderId);
        setAlternatives(alts);
      }
    } catch {
      setError("Не удалось загрузить заказ");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, [orderId]);

  async function handleStatusChange(next: PharmacyOrderStatus) {
    setProcessing(true);
    try {
      await api.updateOrderStatus(orderId, next);
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setProcessing(false);
    }
  }

  async function handleItemAvailability(itemId: string, isAvailable: boolean) {
    setProcessing(true);
    try {
      await api.updateOrderItemAvailability(orderId, itemId, isAvailable);
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setProcessing(false);
    }
  }

  if (loading) {
    return <div className="ph-loading"><div className="ph-spinner" /><span>Загрузка заказа...</span></div>;
  }

  if (error || !order) {
    return (
      <div className="ph-error">
        <XCircle size={20} />
        <span>{error || "Заказ не найден"}</span>
        <button className="secondary-button" onClick={onBack}>Назад</button>
      </div>
    );
  }

  const transitions = getTransitions(order.status);
  const hasUnavailable = order.items.some((i) => !i.isAvailable);

  return (
    <div className="content-stack">
      <div className="ph-form-header">
        <button className="ghost-button" onClick={onBack}>
          <ArrowLeft size={16} />
          Все заказы
        </button>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <h2 style={{ margin: 0 }}>Заказ #{order.id.slice(-6).toUpperCase()}</h2>
          <span className={`status-badge ${STATUS_CLASS[order.status] || "badge-gray"}`}>
            {STATUS_LABELS[order.status]}
          </span>
        </div>
      </div>

      {error && <div className="error-text">{error}</div>}

      <div className="ph-order-detail-grid">
        {/* Left: items */}
        <div className="ph-order-detail-main">
          {/* Unavailability warning */}
          {hasUnavailable && (
            <div className="ph-alert ph-alert-amber ph-alert-block">
              <AlertTriangle size={18} />
              <div>
                <strong>Один или несколько товаров отсутствуют</strong>
                <p style={{ margin: "4px 0 0", fontSize: 13 }}>
                  Замену препарата необходимо согласовать с врачом или фармацевтом.
                </p>
              </div>
            </div>
          )}

          <div className="section-band">
            <h3 style={{ margin: 0 }}>Список товаров</h3>
            <table className="ph-table">
              <thead>
                <tr>
                  <th>Препарат</th>
                  <th>Кол-во</th>
                  <th>Цена</th>
                  <th>Сумма</th>
                  <th>Наличие</th>
                </tr>
              </thead>
              <tbody>
                {order.items.map((item) => {
                  const itemAlts = alternatives[item.id] || [];
                  return (
                    <>
                      <tr key={item.id} style={{ background: !item.isAvailable ? "#fff8f0" : undefined }}>
                        <td><strong>{item.productName}</strong></td>
                        <td>{item.quantity}</td>
                        <td>{item.unitPrice.toLocaleString("ru-KZ")} ₸</td>
                        <td><strong>{(item.quantity * item.unitPrice).toLocaleString("ru-KZ")} ₸</strong></td>
                        <td>
                          <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
                            {item.isAvailable
                              ? <span className="status-badge badge-green">Есть</span>
                              : <span className="status-badge badge-red">Нет</span>}
                            {["NEW", "CONFIRMED", "PREPARING"].includes(order.status) && (
                              <button
                                className="ph-icon-btn"
                                id={`toggle-item-${item.id}`}
                                title={item.isAvailable ? "Отметить отсутствующим" : "Отметить наличие"}
                                onClick={() => handleItemAvailability(item.id, !item.isAvailable)}
                                disabled={processing}
                              >
                                {item.isAvailable ? <XCircle size={14} color="#8a1f17" /> : <CheckCircle size={14} color="#006f63" />}
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                      {/* Alternatives row */}
                      {!item.isAvailable && itemAlts.length > 0 && (
                        <tr key={`${item.id}-alts`}>
                          <td colSpan={5}>
                            <div className="ph-alternatives">
                              <span className="ph-alternatives-label">Возможные замены (согласовать с врачом):</span>
                              {itemAlts.map((alt) => (
                                <div key={alt.id} className="ph-alt-item">
                                  <Package size={14} color="#007f6d" />
                                  <span>{alt.name}</span>
                                  <span className="ph-alt-price">{alt.price.toLocaleString("ru-KZ")} ₸</span>
                                  <span className="ph-alt-stock">ост. {alt.stock}</span>
                                </div>
                              ))}
                            </div>
                          </td>
                        </tr>
                      )}
                    </>
                  );
                })}
              </tbody>
            </table>

            {/* Total */}
            <div className="ph-order-total">
              <span>Итого</span>
              <strong>{order.totalPrice.toLocaleString("ru-KZ")} ₸</strong>
            </div>
          </div>
        </div>

        {/* Right: info + actions */}
        <div className="ph-order-detail-side">
          <div className="section-band ph-order-info-card">
            <h3 style={{ margin: 0 }}>Информация о заказе</h3>

            <div className="ph-info-row"><span>Пациент</span><strong>{order.patientName}</strong></div>
            <div className="ph-info-row"><span>Телефон</span><strong>{order.patientPhone}</strong></div>
            <div className="ph-info-row"><span>Дата</span><strong>{formatDate(order.createdAt)}</strong></div>
            <div className="ph-info-row">
              <span>Доставка</span>
              <strong>{order.deliveryType === "pickup" ? "Самовывоз" : "Доставка"}</strong>
            </div>
            {order.deliveryAddress && (
              <div className="ph-info-row"><span>Адрес</span><strong>{order.deliveryAddress}</strong></div>
            )}
            {order.comment && (
              <div className="ph-info-row">
                <span>Комментарий</span>
                <strong style={{ wordBreak: "break-word" }}>{order.comment}</strong>
              </div>
            )}
          </div>

          {/* Actions */}
          {transitions.length > 0 && (
            <div className="section-band">
              <h3 style={{ margin: 0 }}>Действия</h3>
              <div style={{ display: "grid", gap: 8 }}>
                {transitions.map((t) => (
                  <button
                    key={t.next}
                    id={`order-action-${t.next}`}
                    className={t.style}
                    disabled={processing}
                    onClick={() => handleStatusChange(t.next)}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
