import { Bot, RefreshCcw } from "lucide-react";
import type { Prescription } from "../api/api";
import { StatusBadge } from "../components/StatusBadge";

type PrescriptionsPageProps = {
  prescriptions: Prescription[];
  loading: boolean;
  onRefresh: () => void;
  onAnalyze: (id: string) => Promise<void>;
};

export function PrescriptionsPage({ prescriptions, loading, onRefresh, onAnalyze }: PrescriptionsPageProps) {
  return (
    <section className="section-band">
      <div className="section-header">
        <h2>Созданные назначения</h2>
        <button className="secondary-button" onClick={onRefresh} disabled={loading}>
          <RefreshCcw size={18} />
          Обновить
        </button>
      </div>

      <div className="prescription-list">
        {prescriptions.map((prescription) => (
          <article key={prescription.id} className="prescription-item">
            <div className="prescription-head">
              <div>
                <strong>{prescription.patient.fullName}</strong>
                <span>{new Date(prescription.createdAt).toLocaleString("ru-RU")}</span>
              </div>
              <StatusBadge status={prescription.status} />
            </div>
            <h3>{prescription.diagnosis}</h3>
            <p>{prescription.rawText}</p>
            {prescription.aiSummary && <div className="ai-summary">{prescription.aiSummary}</div>}
            <div className="medicine-tags">
              {prescription.medicines.map((medicine) => (
                <span key={medicine.id}>
                  {medicine.medicineName} · {medicine.dosage}
                </span>
              ))}
            </div>
            <button className="secondary-button" onClick={() => onAnalyze(prescription.id)}>
              <Bot size={18} />
              AI analyze
            </button>
          </article>
        ))}
        {!prescriptions.length && <p className="empty-text">Назначений пока нет.</p>}
      </div>
    </section>
  );
}

