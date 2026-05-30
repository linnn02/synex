import { useEffect, useState } from "react";
import { Building2, Save } from "lucide-react";
import type { Pharmacy } from "../../api/api";
import { api } from "../../api/api";

type FormData = {
  name: string;
  address: string;
  city: string;
  phone: string;
  email: string;
  workingHours: string;
  deliveryEnabled: boolean;
  pickupEnabled: boolean;
};

function toForm(p: Pharmacy): FormData {
  return {
    name: p.name,
    address: p.address,
    city: p.city,
    phone: p.phone,
    email: p.email,
    workingHours: p.workingHours,
    deliveryEnabled: p.deliveryEnabled,
    pickupEnabled: p.pickupEnabled
  };
}

export function PharmacyProfilePage() {
  const [pharmacy, setPharmacy] = useState<Pharmacy | null>(null);
  const [form, setForm] = useState<FormData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    api.pharmacyProfile()
      .then((p) => { setPharmacy(p); setForm(toForm(p)); })
      .catch(() => setError("Не удалось загрузить профиль"))
      .finally(() => setLoading(false));
  }, []);

  function set(field: keyof FormData, value: string | boolean) {
    setForm((prev) => prev ? { ...prev, [field]: value } : prev);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form) return;
    setSaving(true);
    setError("");
    setSaved(false);
    try {
      const updated = await api.updatePharmacyProfile(form);
      setPharmacy(updated);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (e: any) {
      setError(e.message || "Ошибка сохранения");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div className="ph-loading"><div className="ph-spinner" /></div>;

  if (!form || !pharmacy) return <div className="ph-error"><span>{error || "Профиль недоступен"}</span></div>;

  return (
    <div className="content-stack">
      {/* Header card */}
      <div className="ph-welcome-card">
        <div className="ph-welcome-icon">
          <Building2 size={22} />
        </div>
        <div>
          <strong>{pharmacy.name}</strong>
          <span>БИН: {pharmacy.bin}</span>
        </div>
        <div className="ph-welcome-badges">
          <span className="ph-tag ph-tag-green">Подключено к Halyk MedCare</span>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        {error && <div className="error-text">{error}</div>}
        {saved && <div className="ph-success-toast">✓ Профиль сохранён</div>}

        <div className="ph-form-grid">
          <div className="ph-form-col">
            <div className="section-band">
              <h3 className="ph-form-section-title">Реквизиты</h3>

              <label className="ph-label">
                Название аптеки
                <input id="profile-name" className="ph-input" required value={form.name} onChange={(e) => set("name", e.target.value)} />
              </label>

              <label className="ph-label">
                Город
                <input id="profile-city" className="ph-input" value={form.city} onChange={(e) => set("city", e.target.value)} />
              </label>

              <label className="ph-label">
                Адрес
                <input id="profile-address" className="ph-input" value={form.address} onChange={(e) => set("address", e.target.value)} />
              </label>

              <label className="ph-label">
                Телефон
                <input id="profile-phone" className="ph-input" value={form.phone} onChange={(e) => set("phone", e.target.value)} />
              </label>

              <label className="ph-label">
                Email
                <input id="profile-email" className="ph-input" type="email" value={form.email} onChange={(e) => set("email", e.target.value)} />
              </label>

              <label className="ph-label">
                График работы
                <input id="profile-hours" className="ph-input" placeholder="08:00–22:00 ежедневно" value={form.workingHours} onChange={(e) => set("workingHours", e.target.value)} />
              </label>
            </div>
          </div>

          <div className="ph-form-col">
            <div className="section-band">
              <h3 className="ph-form-section-title">Способы получения</h3>

              <label className="ph-checkbox-label ph-checkbox-large">
                <input
                  id="profile-pickup"
                  type="checkbox"
                  checked={form.pickupEnabled}
                  onChange={(e) => set("pickupEnabled", e.target.checked)}
                />
                <div>
                  <strong>Самовывоз</strong>
                  <span>Клиент забирает заказ из аптеки</span>
                </div>
              </label>

              <label className="ph-checkbox-label ph-checkbox-large">
                <input
                  id="profile-delivery"
                  type="checkbox"
                  checked={form.deliveryEnabled}
                  onChange={(e) => set("deliveryEnabled", e.target.checked)}
                />
                <div>
                  <strong>Доставка</strong>
                  <span>Курьерская доставка по адресу</span>
                </div>
              </label>
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end" }}>
              <button type="submit" className="primary-button" id="btn-save-profile" disabled={saving}>
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
