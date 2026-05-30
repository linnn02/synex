import { useEffect, useState } from "react";
import { AlertCircle, Edit2, Package, PlusCircle, Search, Trash2 } from "lucide-react";
import type { PharmacyProduct } from "../../api/api";
import { api } from "../../api/api";

type Props = {
  onNavigate: (view: string) => void;
};

const FORM_LABELS: Record<string, string> = {
  TABLET: "Таблетки",
  SYRUP: "Сироп",
  SPRAY: "Спрей",
  CAPSULE: "Капсулы",
  DROPS: "Капли",
  OINTMENT: "Мазь",
  INJECTION: "Инъекция",
  OTHER: "Другое"
};

function stockBadge(product: PharmacyProduct) {
  if (product.stock <= 0) return <span className="status-badge badge-red">Нет в наличии</span>;
  if (product.stock <= product.minStock) return <span className="status-badge badge-amber">Мало</span>;
  return <span className="status-badge badge-green">В наличии</span>;
}

export function PharmacyProductsPage({ onNavigate }: Props) {
  const [products, setProducts] = useState<PharmacyProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [stockStatus, setStockStatus] = useState("");
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [error, setError] = useState("");

  const categories = Array.from(new Set(products.map((p) => p.category).filter(Boolean))) as string[];

  async function load() {
    setLoading(true);
    setError("");
    try {
      const data = await api.pharmacyProducts({ search, category, stockStatus });
      setProducts(data);
    } catch {
      setError("Не удалось загрузить товары");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, [search, category, stockStatus]);

  async function handleDelete(id: string) {
    try {
      await api.deletePharmacyProduct(id);
      setDeleteId(null);
      load();
    } catch {
      alert("Не удалось удалить товар");
    }
  }

  return (
    <div className="content-stack">
      {/* Toolbar */}
      <div className="crm-toolbar">
        <div className="search-field" style={{ maxWidth: 360 }}>
          <Search size={16} color="#60727f" />
          <input
            id="product-search"
            placeholder="Поиск по названию или веществу..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div style={{ display: "flex", gap: 8, flex: 1, flexWrap: "wrap" }}>
          <select className="ph-select" id="filter-category" value={category} onChange={(e) => setCategory(e.target.value)}>
            <option value="">Все категории</option>
            {categories.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
          <select className="ph-select" id="filter-stock" value={stockStatus} onChange={(e) => setStockStatus(e.target.value)}>
            <option value="">Все остатки</option>
            <option value="in_stock">В наличии</option>
            <option value="low">Мало</option>
            <option value="out">Нет в наличии</option>
          </select>
        </div>
        <button className="primary-button" id="btn-add-product" onClick={() => onNavigate("products-add")}>
          <PlusCircle size={16} />
          Добавить товар
        </button>
      </div>

      {/* Table */}
      <div className="section-band" style={{ padding: 0 }}>
        {loading ? (
          <div className="ph-loading">
            <div className="ph-spinner" />
            <span>Загрузка...</span>
          </div>
        ) : error ? (
          <div className="ph-error">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        ) : products.length === 0 ? (
          <div className="ph-empty">
            <Package size={32} color="#cfdde2" />
            <span>Товары не найдены</span>
          </div>
        ) : (
          <table className="ph-table">
            <thead>
              <tr>
                <th>Название / вещество</th>
                <th>Форма / дозировка</th>
                <th>Категория</th>
                <th>Цена</th>
                <th>Остаток</th>
                <th>Статус</th>
                <th>Рецепт</th>
                <th style={{ width: 100 }}>Действия</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => (
                <tr key={p.id}>
                  <td>
                    <strong>{p.name}</strong>
                    <span>{p.activeSubstance}</span>
                  </td>
                  <td>
                    <strong>{FORM_LABELS[p.form] || p.form}</strong>
                    <span>{p.dosage}</span>
                  </td>
                  <td>{p.category || "—"}</td>
                  <td><strong>{p.price.toLocaleString("ru-KZ")} ₸</strong></td>
                  <td>
                    <strong>{p.stock}</strong>
                    <span style={{ fontSize: 12, color: "#60727f" }}>мин. {p.minStock}</span>
                  </td>
                  <td>{stockBadge(p)}</td>
                  <td>
                    {p.requiresPrescription
                      ? <span className="status-badge badge-amber">Рецепт</span>
                      : <span className="status-badge badge-gray">Без рецепта</span>}
                  </td>
                  <td>
                    <div className="ph-row-actions">
                      <button
                        className="ph-icon-btn ph-icon-btn-edit"
                        id={`edit-product-${p.id}`}
                        title="Редактировать"
                        onClick={() => onNavigate(`products-edit-${p.id}`)}
                      >
                        <Edit2 size={14} />
                      </button>
                      <button
                        className="ph-icon-btn ph-icon-btn-danger"
                        id={`delete-product-${p.id}`}
                        title="Скрыть товар"
                        onClick={() => setDeleteId(p.id)}
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Confirm delete modal */}
      {deleteId && (
        <div className="ph-modal-overlay">
          <div className="ph-modal">
            <h3>Скрыть товар?</h3>
            <p>Товар будет помечен как недоступный. Данные сохранятся.</p>
            <div className="ph-modal-actions">
              <button className="secondary-button" onClick={() => setDeleteId(null)}>Отмена</button>
              <button className="ph-danger-button" onClick={() => handleDelete(deleteId)}>Скрыть</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
