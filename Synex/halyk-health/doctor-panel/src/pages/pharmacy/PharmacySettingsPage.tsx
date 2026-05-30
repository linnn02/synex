import { useState } from "react";
import { Bell, Globe, Lock, LogOut } from "lucide-react";
import { api } from "../../api/api";
import { clearToken } from "../../api/api";

type Props = {
  onLogout: () => void;
};

export function PharmacySettingsPage({ onLogout }: Props) {
  const [lang, setLang] = useState("ru");
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);

  const [oldPwd, setOldPwd] = useState("");
  const [newPwd, setNewPwd] = useState("");
  const [confirmPwd, setConfirmPwd] = useState("");
  const [pwdError, setPwdError] = useState("");
  const [pwdSaved, setPwdSaved] = useState(false);

  function handlePasswordChange(e: React.FormEvent) {
    e.preventDefault();
    setPwdError("");
    if (newPwd.length < 6) { setPwdError("Пароль должен содержать минимум 6 символов"); return; }
    if (newPwd !== confirmPwd) { setPwdError("Пароли не совпадают"); return; }
    // In a real app, call a PATCH /api/auth/change-password endpoint
    setPwdSaved(true);
    setOldPwd(""); setNewPwd(""); setConfirmPwd("");
    setTimeout(() => setPwdSaved(false), 3000);
  }

  return (
    <div className="content-stack">
      {/* Language */}
      <div className="section-band">
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 16 }}>
          <Globe size={18} color="#007f6d" />
          <h3 style={{ margin: 0 }}>Язык интерфейса</h3>
        </div>
        <div className="ph-lang-options">
          <label className={`ph-lang-option ${lang === "ru" ? "selected" : ""}`}>
            <input type="radio" name="lang" value="ru" checked={lang === "ru"} onChange={() => setLang("ru")} />
            🇷🇺 Русский
          </label>
          <label className={`ph-lang-option ${lang === "kz" ? "selected" : ""}`}>
            <input type="radio" name="lang" value="kz" checked={lang === "kz"} onChange={() => setLang("kz")} />
            🇰🇿 Қазақша
          </label>
        </div>
      </div>

      {/* Notifications */}
      <div className="section-band">
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 16 }}>
          <Bell size={18} color="#007f6d" />
          <h3 style={{ margin: 0 }}>Уведомления</h3>
        </div>
        <label className="ph-checkbox-label ph-checkbox-large">
          <input
            id="notifications-toggle"
            type="checkbox"
            checked={notificationsEnabled}
            onChange={(e) => setNotificationsEnabled(e.target.checked)}
          />
          <div>
            <strong>Уведомления о новых заказах</strong>
            <span>Получать оповещения при поступлении нового заказа</span>
          </div>
        </label>
      </div>

      {/* Password */}
      <div className="section-band">
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 16 }}>
          <Lock size={18} color="#007f6d" />
          <h3 style={{ margin: 0 }}>Смена пароля</h3>
        </div>

        <form onSubmit={handlePasswordChange} style={{ maxWidth: 400 }}>
          {pwdError && <div className="error-text" style={{ marginBottom: 12 }}>{pwdError}</div>}
          {pwdSaved && <div className="ph-success-toast">✓ Пароль обновлён</div>}

          <div className="ph-form-grid-1" style={{ gap: 12 }}>
            <label className="ph-label">
              Текущий пароль
              <input id="old-password" className="ph-input" type="password" required value={oldPwd} onChange={(e) => setOldPwd(e.target.value)} />
            </label>
            <label className="ph-label">
              Новый пароль
              <input id="new-password" className="ph-input" type="password" required minLength={6} value={newPwd} onChange={(e) => setNewPwd(e.target.value)} />
            </label>
            <label className="ph-label">
              Подтвердите пароль
              <input id="confirm-password" className="ph-input" type="password" required value={confirmPwd} onChange={(e) => setConfirmPwd(e.target.value)} />
            </label>
          </div>

          <button type="submit" className="primary-button" id="btn-change-password" style={{ marginTop: 16 }}>
            <Lock size={14} />
            Изменить пароль
          </button>
        </form>
      </div>

      {/* Logout */}
      <div className="section-band">
        <h3 style={{ margin: "0 0 12px" }}>Выйти из аккаунта</h3>
        <button
          className="ph-danger-button"
          id="btn-logout"
          onClick={() => { clearToken(); onLogout(); }}
        >
          <LogOut size={16} />
          Выйти
        </button>
      </div>
    </div>
  );
}
