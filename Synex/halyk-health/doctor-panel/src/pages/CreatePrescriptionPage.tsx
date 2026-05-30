import { FormEvent, useState } from "react";
import { Bot, Send, X } from "lucide-react";
import type { Appointment, Prescription } from "../api/api";
import { api } from "../api/api";

type CreatePrescriptionPageProps = {
  appointment: Appointment;
  onCancel: () => void;
  onCreated: (prescription: Prescription) => void;
};

export function CreatePrescriptionPage({ appointment, onCancel, onCreated }: CreatePrescriptionPageProps) {
  const [diagnosis, setDiagnosis] = useState("ОРВИ");
  const [rawText, setRawText] = useState(
    "Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре."
  );
  const [doctorComment, setDoctorComment] = useState("Контроль состояния через 3 дня.");
  const [analyzeAfterCreate, setAnalyzeAfterCreate] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      const created = await api.createPrescription({
        appointmentId: appointment.id,
        diagnosis,
        rawText,
        doctorComment
      });
      const result = analyzeAfterCreate ? await api.analyzePrescription(created.id) : created;
      onCreated(result);
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Не удалось создать назначение");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="section-band">
      <div className="section-header">
        <div>
          <h2>Создать назначение</h2>
          <p>{appointment.patient.fullName}</p>
        </div>
        <button className="secondary-button" onClick={onCancel}>
          <X size={18} />
          Закрыть
        </button>
      </div>

      <form className="form prescription-form" onSubmit={handleSubmit}>
        <label>
          Appointment ID
          <input value={appointment.id} disabled />
        </label>
        <label>
          Диагноз
          <input value={diagnosis} onChange={(event) => setDiagnosis(event.target.value)} />
        </label>
        <label>
          Текст назначения
          <textarea value={rawText} onChange={(event) => setRawText(event.target.value)} rows={6} />
        </label>
        <label>
          Комментарий врача
          <textarea value={doctorComment} onChange={(event) => setDoctorComment(event.target.value)} rows={3} />
        </label>
        <label className="inline-check">
          <input
            type="checkbox"
            checked={analyzeAfterCreate}
            onChange={(event) => setAnalyzeAfterCreate(event.target.checked)}
          />
          <span>
            <Bot size={17} />
            Запустить AI analyze после отправки
          </span>
        </label>

        {error && <div className="error-text">{error}</div>}

        <button className="primary-button" disabled={loading}>
          <Send size={18} />
          {loading ? "Отправка..." : "Отправить назначение"}
        </button>
      </form>
    </section>
  );
}

