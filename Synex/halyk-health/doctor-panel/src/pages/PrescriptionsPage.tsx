import { Bot, CalendarClock, FileText, Pill, RefreshCcw, Search, ShieldCheck } from "lucide-react";
import { useMemo, useState } from "react";
import type { Prescription, PrescriptionStatus } from "../api/api";
import { StatusBadge } from "../components/StatusBadge";

type PrescriptionsPageProps = {
  prescriptions: Prescription[];
  loading: boolean;
  onRefresh: () => void;
  onAnalyze: (id: string) => Promise<void>;
};

export function PrescriptionsPage({ prescriptions, loading, onRefresh, onAnalyze }: PrescriptionsPageProps) {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<PrescriptionStatus | "ALL">("ALL");

  const filteredPrescriptions = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    return prescriptions.filter((prescription) => {
      const statusMatches = status === "ALL" || prescription.status === status;
      const queryMatches =
        !normalizedQuery ||
        prescription.patient.fullName.toLowerCase().includes(normalizedQuery) ||
        prescription.diagnosis.toLowerCase().includes(normalizedQuery) ||
        prescription.rawText.toLowerCase().includes(normalizedQuery) ||
        prescription.medicines.some((medicine) => medicine.medicineName.toLowerCase().includes(normalizedQuery));

      return statusMatches && queryMatches;
    });
  }, [prescriptions, query, status]);

  const statusCounters = {
    ALL: prescriptions.length,
    SENT: prescriptions.filter((item) => item.status === "SENT").length,
    ACTIVE: prescriptions.filter((item) => item.status === "ACTIVE").length,
    COMPLETED: prescriptions.filter((item) => item.status === "COMPLETED").length,
    DRAFT: prescriptions.filter((item) => item.status === "DRAFT").length
  };

  return (
    <div className="content-stack">
      <section className="crm-toolbar">
        <div className="search-field">
          <Search size={18} />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Поиск по пациенту, диагнозу, лекарству или тексту назначения"
          />
        </div>
        <button className="secondary-button" onClick={onRefresh} disabled={loading}>
          <RefreshCcw size={18} />
          Обновить
        </button>
      </section>

      <section className="status-tabs">
        {(
          [
            ["ALL", "Все"],
            ["SENT", "Отправленные"],
            ["ACTIVE", "Активные"],
            ["COMPLETED", "Завершенные"],
            ["DRAFT", "Черновики"]
          ] as Array<[PrescriptionStatus | "ALL", string]>
        ).map(([value, label]) => (
          <button key={value} className={status === value ? "active" : ""} onClick={() => setStatus(value)}>
            <FileText size={15} />
            {label}
            <span>{statusCounters[value]}</span>
          </button>
        ))}
      </section>

      <section className="prescription-crm-layout">
        <div className="prescription-list">
          {filteredPrescriptions.map((prescription) => (
            <article key={prescription.id} className="prescription-item crm-prescription-item">
              <div className="prescription-head">
                <div>
                  <strong>{prescription.patient.fullName}</strong>
                  <span>{new Date(prescription.createdAt).toLocaleString("ru-RU")}</span>
                </div>
                <StatusBadge status={prescription.status} />
              </div>
              <div className="prescription-main">
                <div className="document-icon">
                  <FileText size={22} />
                </div>
                <div>
                  <h3>{prescription.diagnosis}</h3>
                  <p>{prescription.rawText}</p>
                </div>
              </div>
              {prescription.aiSummary && <div className="ai-summary">{prescription.aiSummary}</div>}
              <div className="medicine-tags">
                {prescription.medicines.map((medicine) => (
                  <span key={medicine.id}>
                    <Pill size={14} />
                    {medicine.medicineName} · {medicine.dosage}
                  </span>
                ))}
                {!prescription.medicines.length && <span>Лекарства будут выделены после AI analyze</span>}
              </div>
              <div className="prescription-footer">
                <span>
                  <CalendarClock size={15} />
                  {prescription.medicines.length} препаратов
                </span>
                <button className="secondary-button" onClick={() => onAnalyze(prescription.id)}>
                  <Bot size={18} />
                  AI analyze
                </button>
              </div>
            </article>
          ))}
          {!filteredPrescriptions.length && <p className="empty-text">Назначений по выбранным фильтрам нет.</p>}
        </div>

        <aside className="section-band prescription-aside">
          <div className="section-header">
            <div>
              <h2>Контроль качества</h2>
              <p>AI-помощник работает только с текстом врача</p>
            </div>
          </div>
          <div className="quality-list">
            <div>
              <ShieldCheck size={18} />
              <span>Не ставит диагноз</span>
            </div>
            <div>
              <ShieldCheck size={18} />
              <span>Не назначает лечение</span>
            </div>
            <div>
              <ShieldCheck size={18} />
              <span>Объясняет пациенту назначение</span>
            </div>
          </div>
          <div className="ai-summary">
            ИИ-агент не заменяет врача. Перед заменой препарата пациент должен проконсультироваться с врачом или
            фармацевтом.
          </div>
        </aside>
      </section>
    </div>
  );
}
