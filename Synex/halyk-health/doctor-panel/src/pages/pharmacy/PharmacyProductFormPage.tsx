import { useEffect, useState } from "react";
import { ArrowLeft, Save } from "lucide-react";
import type { PharmacyProduct, PharmacyProductForm } from "../../api/api";
import { api } from "../../api/api";

type Props = {
  productId?: string; // undefined = create mode
  onCancel: () => void;
  onSaved: () => void;
};

const FORM_OPTIONS: { value: PharmacyProductForm; label: string }[] = [
  { value: "TABLET", label: "Таблетки" },
  { value: "SYRUP", label: "Сироп" },
  { value: "SPRAY", label: "Спрей" },
  { value: "CAPSULE", label: "Капсулы" },
  { value: "DROPS", label: "Капли" },
  { value: "OINTMENT", label: "Мазь" },
  { value: "INJECTION", label: "Инъекция" },
  { value: "OTHER", label: "Другое" }
];

type FormData = {
  name: string;
  activeSubstance: string;
  dosage: string;
  form: PharmacyProductForm;
  category: string;
  manufacturer: string;
  price: string;
  stock: string;
  minStock: string;
  imageUrl: string;
  requiresPrescription: boolean;
  isAvailable: boolean;
  description: string;
};

const EMPTY: FormData = {
  name: "",
  activeSubstance: "",
  dosage: "",
  form: "TABLET",
  category: "",
  manufacturer: "",
  price: "",
  stock: "0",
  minStock: "5",
  imageUrl: "",
  requiresPrescription: false,
  isAvailable: true,
  description: ""
};

function toFormData(p: PharmacyProduct): FormData {
  return {
    name: p.name,
    activeSubstance: p.activeSubstance,
    dosage: p.dosage,
    form: p.form,
    category: p.category || "",
    manufacturer: p.manufacturer || "",
    price: String(p.price),
    stock: String(p.stock),
    minStock: String(p.minStock),
    imageUrl: p.imageUrl || "",
    requiresPrescription: p.requiresPrescription,
    isAvailable: p.isAvailable,
    description: p.description || ""
  };
}

export function PharmacyProductFormPage({ productId, onCancel, onSaved }: Props) {
  const [form, setForm] = useState<FormData>(EMPTY);
  const [loading, setLoading] = useState(!!productId);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!productId) return;
    api
      .pharmacyProduct(productId)
      .then((p) => setForm(toFormData(p)))
      .catch(() => setError("Не удалось загрузить товар"))
      .finally(() => setLoading(false));
  }, [productId]);

  function set(field: keyof FormData, value: string | boolean) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setSaving(true);

    const payload = {
      name: form.name.trim(),
      activeSubstance: form.activeSubstance.trim(),
      dosage: form.dosage.trim(),
      form: form.form,
      category: form.category.trim() || undefined,
      manufacturer: form.manufacturer.trim() || undefined,
      price: parseFloat(form.price),
      stock: parseInt(form.stock, 10),
      minStock: parseInt(form.minStock, 10),
      imageUrl: form.imageUrl.trim() || null,
      requiresPrescription: form.requiresPrescription,
      isAvailable: form.isAvailable,
      description: form.description.trim() || undefined
    };

    try {
      if (productId) {
        await api.updatePharmacyProduct(productId, payload);
      } else {
        await api.createPharmacyProduct(payload as any);
      }
      onSaved();
    } catch (err: any) {
      setError(err.message || "Не удалось сохранить товар");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="ph-loading">
        <div className="ph-spinner" />
        <span>Загрузка товара...</span>
      </div>
    );
  }

  return (
    <div className="content-stack">
      <div className="ph-form-header">
        <button className="ghost-button" onClick={onCancel}>
          <ArrowLeft size={16} />
          Назад к товарам
        </button>
        <h2 style={{ margin: 0 }}>{productId ? "Редактировать товар" : "Добавить товар"}</h2>
      </div>

      <form className="ph-product-form" onSubmit={handleSubmit}>
        {error && <div className="error-text">{error}</div>}

        <div className="ph-form-grid">
          {/* Column 1 */}
          <div className="ph-form-col">
            <div className="section-band">
              <h3 className="ph-form-section-title">Основная информация</h3>

              <label className="ph-label">
                Название препарата *
                <input
                  id="product-name"
                  className="ph-input"
                  required
                  placeholder="Парацетамол 500 мг"
                  value={form.name}
                  onChange={(e) => set("name", e.target.value)}
                />
              </label>

              <label className="ph-label">
                Действующее вещество *
                <input
                  id="product-substance"
                  className="ph-input"
                  required
                  placeholder="paracetamol"
                  value={form.activeSubstance}
                  onChange={(e) => set("activeSubstance", e.target.value)}
                />
              </label>

              <div className="ph-row-2">
                <label className="ph-label">
                  Дозировка *
                  <input
                    id="product-dosage"
                    className="ph-input"
                    required
                    placeholder="500 мг"
                    value={form.dosage}
                    onChange={(e) => set("dosage", e.target.value)}
                  />
                </label>

                <label className="ph-label">
                  Форма выпуска *
                  <select
                    id="product-form"
                    className="ph-input"
                    value={form.form}
                    onChange={(e) => set("form", e.target.value)}
                  >
                    {FORM_OPTIONS.map((o) => (
                      <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                  </select>
                </label>
              </div>

              <div className="ph-row-2">
                <label className="ph-label">
                  Категория
                  <input
                    id="product-category"
                    className="ph-input"
                    placeholder="Жаропонижающие"
                    value={form.category}
                    onChange={(e) => set("category", e.target.value)}
                  />
                </label>

                <label className="ph-label">
                  Производитель
                  <input
                    id="product-manufacturer"
                    className="ph-input"
                    placeholder="Bayer"
                    value={form.manufacturer}
                    onChange={(e) => set("manufacturer", e.target.value)}
                  />
                </label>
              </div>

              <label className="ph-label">
                Описание
                <textarea
                  id="product-description"
                  className="ph-input ph-textarea"
                  rows={3}
                  placeholder="Краткое описание назначения препарата..."
                  value={form.description}
                  onChange={(e) => set("description", e.target.value)}
                />
              </label>

              <label className="ph-label">
                Ссылка на фото (imageUrl)
                <input
                  id="product-image"
                  className="ph-input"
                  placeholder="https://..."
                  value={form.imageUrl}
                  onChange={(e) => set("imageUrl", e.target.value)}
                />
              </label>
            </div>
          </div>

          {/* Column 2 */}
          <div className="ph-form-col">
            <div className="section-band">
              <h3 className="ph-form-section-title">Наличие и цена</h3>

              <label className="ph-label">
                Цена (₸) *
                <input
                  id="product-price"
                  className="ph-input"
                  type="number"
                  min="0"
                  step="1"
                  required
                  placeholder="980"
                  value={form.price}
                  onChange={(e) => set("price", e.target.value)}
                />
              </label>

              <div className="ph-row-2">
                <label className="ph-label">
                  Количество на складе
                  <input
                    id="product-stock"
                    className="ph-input"
                    type="number"
                    min="0"
                    value={form.stock}
                    onChange={(e) => set("stock", e.target.value)}
                  />
                </label>

                <label className="ph-label">
                  Минимальный остаток
                  <input
                    id="product-minstock"
                    className="ph-input"
                    type="number"
                    min="0"
                    value={form.minStock}
                    onChange={(e) => set("minStock", e.target.value)}
                  />
                </label>
              </div>

              <label className="ph-checkbox-label">
                <input
                  id="product-prescription"
                  type="checkbox"
                  checked={form.requiresPrescription}
                  onChange={(e) => set("requiresPrescription", e.target.checked)}
                />
                Требуется рецепт
              </label>

              <label className="ph-checkbox-label">
                <input
                  id="product-available"
                  type="checkbox"
                  checked={form.isAvailable}
                  onChange={(e) => set("isAvailable", e.target.checked)}
                />
                Доступен для заказа
              </label>
            </div>

            <div className="ph-form-actions">
              <button type="button" className="secondary-button" onClick={onCancel}>
                Отмена
              </button>
              <button type="submit" className="primary-button" id="btn-save-product" disabled={saving}>
                <Save size={16} />
                {saving ? "Сохранение..." : "Сохранить"}
              </button>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
