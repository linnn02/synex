import { useEffect, useState } from "react";
import { AlertCircle, ChevronDown, History, Minus, Plus } from "lucide-react";
import type { PharmacyProduct, PharmacyStockMovement, StockMovementReason } from "../../api/api";
import { api } from "../../api/api";

const REASON_LABELS: Record<StockMovementReason, string> = {
  SUPPLY: "Поставка",
  SALE: "Продажа",
  WRITE_OFF: "Списание",
  CORRECTION: "Корректировка"
};

const REASON_CLASS: Record<StockMovementReason, string> = {
  SUPPLY: "badge-green",
  SALE: "badge-blue",
  WRITE_OFF: "badge-red",
  CORRECTION: "badge-amber"
};

function formatDate(iso: string) {
  return new Date(iso).toLocaleString("ru-KZ", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}

type MovementModalProps = {
  product: PharmacyProduct;
  mode: "in" | "out";
  onClose: () => void;
  onDone: () => void;
};

function MovementModal({ product, mode, onClose, onDone }: MovementModalProps) {
  const [qty, setQty] = useState("1");
  const [reason, setReason] = useState<StockMovementReason>(mode === "in" ? "SUPPLY" : "WRITE_OFF");
  const [comment, setComment] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const inReasons: StockMovementReason[] = ["SUPPLY", "CORRECTION"];
  const outReasons: StockMovementReason[] = ["SALE", "WRITE_OFF", "CORRECTION"];
  const reasons = mode === "in" ? inReasons : outReasons;

  async function handle() {
    const quantity = parseInt(qty, 10);
    if (!quantity || quantity <= 0) return;
    setSaving(true);
    setError("");
    try {
      const delta = mode === "in" ? quantity : -quantity;
      await api.updateStock(product.id, delta, reason, comment || undefined);
      onDone();
    } catch (e: any) {
      setError(e.message || "Ошибка");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="ph-modal-overlay">
      <div className="ph-modal">
        <h3>{mode === "in" ? "Поступление товара" : "Списание / продажа"}</h3>
        <p style={{ color: "#60727f", margin: "4px 0 16px" }}>{product.name} · текущий остаток: <strong>{product.stock}</strong></p>

        {error && <div className="error-text" style={{ marginBottom: 12 }}>{error}</div>}

        <label className="ph-label">
          Количество
          <input
            id="movement-qty"
            className="ph-input"
            type="number"
            min="1"
            value={qty}
            onChange={(e) => setQty(e.target.value)}
          />
        </label>

        <label className="ph-label" style={{ marginTop: 12 }}>
          Причина
          <select id="movement-reason" className="ph-input" value={reason} onChange={(e) => setReason(e.target.value as StockMovementReason)}>
            {reasons.map((r) => (
              <option key={r} value={r}>{REASON_LABELS[r]}</option>
            ))}
          </select>
        </label>

        <label className="ph-label" style={{ marginTop: 12 }}>
          Комментарий (необязательно)
          <input
            id="movement-comment"
            className="ph-input"
            placeholder="Поставщик, номер партии..."
            value={comment}
            onChange={(e) => setComment(e.target.value)}
          />
        </label>

        <div className="ph-modal-actions" style={{ marginTop: 20 }}>
          <button className="secondary-button" onClick={onClose}>Отмена</button>
          <button
            className="primary-button"
            id="btn-save-movement"
            onClick={handle}
            disabled={saving}
          >
            {saving ? "Сохранение..." : "Сохранить"}
          </button>
        </div>
      </div>
    </div>
  );
}

type HistoryPanelProps = {
  product: PharmacyProduct;
  onClose: () => void;
};

function HistoryPanel({ product, onClose }: HistoryPanelProps) {
  const [movements, setMovements] = useState<PharmacyStockMovement[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .stockMovements(product.id)
      .then(setMovements)
      .finally(() => setLoading(false));
  }, [product.id]);

  return (
    <div className="ph-modal-overlay">
      <div className="ph-modal ph-modal-wide">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <h3 style={{ margin: 0 }}>История остатков — {product.name}</h3>
          <button className="secondary-button" onClick={onClose}>Закрыть</button>
        </div>

        {loading ? (
          <div className="ph-loading"><div className="ph-spinner" /></div>
        ) : movements.length === 0 ? (
          <div className="ph-empty">История пуста</div>
        ) : (
          <table className="ph-table">
            <thead>
              <tr>
                <th>Дата</th>
                <th>Количество</th>
                <th>Причина</th>
                <th>Комментарий</th>
              </tr>
            </thead>
            <tbody>
              {movements.map((m) => (
                <tr key={m.id}>
                  <td>{formatDate(m.createdAt)}</td>
                  <td>
                    <strong style={{ color: m.quantity > 0 ? "#006f63" : "#8a1f17" }}>
                      {m.quantity > 0 ? `+${m.quantity}` : m.quantity}
                    </strong>
                  </td>
                  <td>
                    <span className={`status-badge ${REASON_CLASS[m.reason as StockMovementReason]}`}>
                      {REASON_LABELS[m.reason as StockMovementReason] || m.reason}
                    </span>
                  </td>
                  <td>{m.comment || "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

export function PharmacyStockPage() {
  const [products, setProducts] = useState<PharmacyProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [movementTarget, setMovementTarget] = useState<{ product: PharmacyProduct; mode: "in" | "out" } | null>(null);
  const [historyTarget, setHistoryTarget] = useState<PharmacyProduct | null>(null);

  async function load() {
    setLoading(true);
    setError("");
    try {
      setProducts(await api.pharmacyProducts());
    } catch {
      setError("Не удалось загрузить товары");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  const lowStock = products.filter((p) => p.stock > 0 && p.stock <= p.minStock);
  const outOfStock = products.filter((p) => p.stock <= 0);

  return (
    <div className="content-stack">
      {/* Summary row */}
      {!loading && (
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
          {lowStock.length > 0 && (
            <div className="ph-alert ph-alert-amber">
              <AlertCircle size={16} />
              <span>{lowStock.length} товаров с низким остатком</span>
            </div>
          )}
          {outOfStock.length > 0 && (
            <div className="ph-alert ph-alert-red">
              <AlertCircle size={16} />
              <span>{outOfStock.length} товаров нет в наличии</span>
            </div>
          )}
        </div>
      )}

      <div className="section-band" style={{ padding: 0 }}>
        {loading ? (
          <div className="ph-loading"><div className="ph-spinner" /></div>
        ) : error ? (
          <div className="ph-error"><AlertCircle size={16} /><span>{error}</span></div>
        ) : (
          <table className="ph-table">
            <thead>
              <tr>
                <th>Препарат</th>
                <th>Категория</th>
                <th>Текущий остаток</th>
                <th>Мин. остаток</th>
                <th>Статус</th>
                <th style={{ width: 180 }}>Действия</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => {
                const isLow = p.stock > 0 && p.stock <= p.minStock;
                const isOut = p.stock <= 0;
                return (
                  <tr key={p.id}>
                    <td>
                      <strong>{p.name}</strong>
                      <span>{p.dosage} · {p.activeSubstance}</span>
                    </td>
                    <td>{p.category || "—"}</td>
                    <td>
                      <strong style={{ color: isOut ? "#8a1f17" : isLow ? "#936300" : "#006f63", fontSize: 18 }}>
                        {p.stock}
                      </strong>
                    </td>
                    <td>{p.minStock}</td>
                    <td>
                      {isOut
                        ? <span className="status-badge badge-red">Нет в наличии</span>
                        : isLow
                        ? <span className="status-badge badge-amber">Мало</span>
                        : <span className="status-badge badge-green">В наличии</span>}
                    </td>
                    <td>
                      <div className="ph-row-actions">
                        <button
                          className="ph-action-mini ph-action-mini-green"
                          id={`stock-in-${p.id}`}
                          title="Поступление"
                          onClick={() => setMovementTarget({ product: p, mode: "in" })}
                        >
                          <Plus size={13} />
                          Поступление
                        </button>
                        <button
                          className="ph-action-mini ph-action-mini-red"
                          id={`stock-out-${p.id}`}
                          title="Списание"
                          onClick={() => setMovementTarget({ product: p, mode: "out" })}
                        >
                          <Minus size={13} />
                          Списание
                        </button>
                        <button
                          className="ph-icon-btn"
                          title="История"
                          onClick={() => setHistoryTarget(p)}
                        >
                          <History size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {movementTarget && (
        <MovementModal
          product={movementTarget.product}
          mode={movementTarget.mode}
          onClose={() => setMovementTarget(null)}
          onDone={() => { setMovementTarget(null); load(); }}
        />
      )}

      {historyTarget && (
        <HistoryPanel
          product={historyTarget}
          onClose={() => setHistoryTarget(null)}
        />
      )}
    </div>
  );
}
