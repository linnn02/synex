import { useEffect, useState } from "react";
import { AlertCircle, PlusCircle, UserCheck, UserX } from "lucide-react";
import type { PharmacyStaffEntry } from "../../api/api";
import { api } from "../../api/api";

const ROLE_LABELS: Record<string, string> = {
  PHARMACY_ADMIN: "Администратор аптеки",
  PHARMACY_STAFF: "Сотрудник аптеки"
};

type NewStaffForm = {
  fullName: string;
  email: string;
  phone: string;
  password: string;
  role: "PHARMACY_ADMIN" | "PHARMACY_STAFF";
};

const EMPTY_FORM: NewStaffForm = {
  fullName: "",
  email: "",
  phone: "",
  password: "",
  role: "PHARMACY_STAFF"
};

export function PharmacyStaffPage() {
  const [staff, setStaff] = useState<PharmacyStaffEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<NewStaffForm>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  async function load() {
    setLoading(true);
    try {
      setStaff(await api.pharmacyStaff());
    } catch {
      setError("Не удалось загрузить сотрудников");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  function setF(field: keyof NewStaffForm, value: string) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleAdd(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");
    try {
      await api.addPharmacyStaff(form);
      setShowForm(false);
      setForm(EMPTY_FORM);
      load();
    } catch (e: any) {
      setError(e.message || "Не удалось добавить сотрудника");
    } finally {
      setSaving(false);
    }
  }

  async function toggleActive(entry: PharmacyStaffEntry) {
    try {
      await api.updatePharmacyStaff(entry.id, { isActive: !entry.isActive });
      load();
    } catch {
      alert("Не удалось изменить статус");
    }
  }

  async function changeRole(entry: PharmacyStaffEntry, role: "PHARMACY_ADMIN" | "PHARMACY_STAFF") {
    try {
      await api.updatePharmacyStaff(entry.id, { role });
      load();
    } catch {
      alert("Не удалось изменить роль");
    }
  }

  return (
    <div className="content-stack">
      <div style={{ display: "flex", justifyContent: "flex-end" }}>
        <button className="primary-button" id="btn-add-staff" onClick={() => setShowForm(true)}>
          <PlusCircle size={16} />
          Добавить сотрудника
        </button>
      </div>

      {/* Add form */}
      {showForm && (
        <div className="ph-modal-overlay">
          <div className="ph-modal">
            <h3>Добавить сотрудника</h3>
            {error && <div className="error-text" style={{ marginBottom: 12 }}>{error}</div>}
            <form onSubmit={handleAdd}>
              <div className="ph-form-grid-1">
                <label className="ph-label">
                  ФИО *
                  <input id="staff-name" className="ph-input" required value={form.fullName} onChange={(e) => setF("fullName", e.target.value)} />
                </label>
                <label className="ph-label">
                  Email *
                  <input id="staff-email" className="ph-input" type="email" required value={form.email} onChange={(e) => setF("email", e.target.value)} />
                </label>
                <label className="ph-label">
                  Телефон *
                  <input id="staff-phone" className="ph-input" required placeholder="+77010000000" value={form.phone} onChange={(e) => setF("phone", e.target.value)} />
                </label>
                <label className="ph-label">
                  Пароль *
                  <input id="staff-password" className="ph-input" type="password" required minLength={6} value={form.password} onChange={(e) => setF("password", e.target.value)} />
                </label>
                <label className="ph-label">
                  Роль
                  <select id="staff-role" className="ph-input" value={form.role} onChange={(e) => setF("role", e.target.value)}>
                    <option value="PHARMACY_STAFF">Сотрудник аптеки</option>
                    <option value="PHARMACY_ADMIN">Администратор аптеки</option>
                  </select>
                </label>
              </div>
              <div className="ph-modal-actions" style={{ marginTop: 16 }}>
                <button type="button" className="secondary-button" onClick={() => { setShowForm(false); setError(""); }}>Отмена</button>
                <button type="submit" className="primary-button" id="btn-save-staff" disabled={saving}>
                  {saving ? "Добавление..." : "Добавить"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="section-band" style={{ padding: 0 }}>
        {loading ? (
          <div className="ph-loading"><div className="ph-spinner" /></div>
        ) : staff.length === 0 ? (
          <div className="ph-empty">
            <AlertCircle size={32} color="#cfdde2" />
            <span>Сотрудников нет</span>
          </div>
        ) : (
          <table className="ph-table">
            <thead>
              <tr>
                <th>Сотрудник</th>
                <th>Контакты</th>
                <th>Роль</th>
                <th>Статус</th>
                <th style={{ width: 160 }}>Действия</th>
              </tr>
            </thead>
            <tbody>
              {staff.map((entry) => (
                <tr key={entry.id} style={{ opacity: entry.isActive ? 1 : 0.6 }}>
                  <td><strong>{entry.user.fullName}</strong></td>
                  <td>
                    <strong>{entry.user.email}</strong>
                    <span>{entry.user.phone}</span>
                  </td>
                  <td>
                    <select
                      className="ph-select ph-select-inline"
                      id={`staff-role-${entry.id}`}
                      value={entry.user.role}
                      onChange={(e) => changeRole(entry, e.target.value as "PHARMACY_ADMIN" | "PHARMACY_STAFF")}
                    >
                      <option value="PHARMACY_STAFF">Сотрудник аптеки</option>
                      <option value="PHARMACY_ADMIN">Администратор аптеки</option>
                    </select>
                  </td>
                  <td>
                    {entry.isActive
                      ? <span className="status-badge badge-green">Активен</span>
                      : <span className="status-badge badge-gray">Отключён</span>}
                  </td>
                  <td>
                    <button
                      className={`ph-action-mini ${entry.isActive ? "ph-action-mini-red" : "ph-action-mini-green"}`}
                      id={`toggle-staff-${entry.id}`}
                      onClick={() => toggleActive(entry)}
                    >
                      {entry.isActive ? <><UserX size={13} /> Отключить</> : <><UserCheck size={13} /> Включить</>}
                    </button>
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
