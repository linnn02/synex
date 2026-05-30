import { FormEvent, useState } from "react";
import {
  Bot,
  CalendarClock,
  ClipboardList,
  FileText,
  Pill,
  Plus,
  Send,
  Sparkles,
  Trash2,
  UserRound,
  X
} from "lucide-react";
import type { Appointment, Prescription } from "../api/api";
import { api } from "../api/api";

type CreatePrescriptionPageProps = {
  appointment: Appointment;
  onCancel: () => void;
  onCreated: (prescription: Prescription) => void;
};

type MedicineDraft = {
  medicineName: string;
  dosage: string;
  frequency: string;
  duration: string;
  instruction: string;
  quantityNeeded: number;
  activeSubstance: string;
};

const emptyMedicine: MedicineDraft = {
  medicineName: "",
  dosage: "",
  frequency: "",
  duration: "",
  instruction: "",
  quantityNeeded: 1,
  activeSubstance: ""
};

const templates: Array<{
  label: string;
  diagnosis: string;
  text: string;
  comment: string;
  medicines: MedicineDraft[];
}> = [
  {
    label: "ОРВИ",
    diagnosis: "ОРВИ",
    text: "Парацетамол 500 мг при температуре. Спрей для горла 3 раза в день 5 дней. Витамин C 500 мг 1 раз в день 10 дней.",
    comment: "Пить больше жидкости, контроль температуры. Повторный прием при ухудшении состояния.",
    medicines: [
      {
        medicineName: "Парацетамол",
        dosage: "500 мг",
        frequency: "При температуре",
        duration: "До 5 дней",
        instruction: "После еды, не превышать дозировку",
        quantityNeeded: 10,
        activeSubstance: "paracetamol"
      },
      {
        medicineName: "Витамин C",
        dosage: "500 мг",
        frequency: "1 раз в день",
        duration: "10 дней",
        instruction: "После еды",
        quantityNeeded: 10,
        activeSubstance: "ascorbic-acid"
      }
    ]
  },
  {
    label: "Ангина",
    diagnosis: "Острый тонзиллит",
    text: "Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре.",
    comment: "Контроль через 3 дня. При ухудшении состояния обратиться повторно.",
    medicines: [
      {
        medicineName: "Амоксициллин",
        dosage: "500 мг",
        frequency: "3 раза в день",
        duration: "7 дней",
        instruction: "После еды",
        quantityNeeded: 21,
        activeSubstance: "amoxicillin"
      },
      {
        medicineName: "Ибупрофен",
        dosage: "200 мг",
        frequency: "При температуре",
        duration: "По необходимости",
        instruction: "Не превышать дозировку, указанную врачом",
        quantityNeeded: 1,
        activeSubstance: "ibuprofen"
      }
    ]
  },
  {
    label: "Аллергия",
    diagnosis: "Аллергический ринит",
    text: "Лоратадин 10 мг 1 раз в день 7 дней. Спрей для горла при раздражении.",
    comment: "Избегать контакта с предполагаемым аллергеном.",
    medicines: [
      {
        medicineName: "Лоратадин",
        dosage: "10 мг",
        frequency: "1 раз в день",
        duration: "7 дней",
        instruction: "Принимать в одно и то же время",
        quantityNeeded: 7,
        activeSubstance: "loratadine"
      }
    ]
  }
];

export function CreatePrescriptionPage({ appointment, onCancel, onCreated }: CreatePrescriptionPageProps) {
  const [diagnosis, setDiagnosis] = useState("Острый тонзиллит");
  const [rawText, setRawText] = useState(
    "Амоксициллин 500 мг 3 раза в день 7 дней после еды. Ибупрофен 200 мг при температуре."
  );
  const [doctorComment, setDoctorComment] = useState("Контроль состояния через 3 дня.");
  const [medicines, setMedicines] = useState<MedicineDraft[]>(templates[1].medicines);
  const [analyzeAfterCreate, setAnalyzeAfterCreate] = useState(true);
  const [loading, setLoading] = useState(false);
  const [validating, setValidating] = useState(false);
  const [aiCheckResult, setAiCheckResult] = useState<{
    isComplete: boolean;
    warnings: string[];
    suggestions: string[];
  } | null>(null);
  const [error, setError] = useState("");

  const validMedicines = medicines.filter(
    (medicine) =>
      medicine.medicineName.trim() &&
      medicine.dosage.trim() &&
      medicine.frequency.trim() &&
      medicine.duration.trim() &&
      medicine.instruction.trim() &&
      medicine.activeSubstance.trim()
  );

  function applyTemplate(template: (typeof templates)[number]) {
    setDiagnosis(template.diagnosis);
    setRawText(template.text);
    setDoctorComment(template.comment);
    setMedicines(template.medicines.map((medicine) => ({ ...medicine })));
  }

  function updateMedicine(index: number, patch: Partial<MedicineDraft>) {
    setMedicines((current) => current.map((medicine, itemIndex) => (itemIndex === index ? { ...medicine, ...patch } : medicine)));
  }

  function addMedicine() {
    setMedicines((current) => [...current, { ...emptyMedicine }]);
  }

  function removeMedicine(index: number) {
    setMedicines((current) => current.filter((_, itemIndex) => itemIndex !== index));
  }

  async function handleAiCheck() {
    if (!rawText.trim()) return;
    setValidating(true);
    setAiCheckResult(null);
    try {
      const result = await api.validatePrescription(rawText);
      setAiCheckResult(result);
    } catch (checkError) {
      console.error(checkError);
    } finally {
      setValidating(false);
    }
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      const created = await api.createPrescription({
        appointmentId: appointment.id,
        diagnosis,
        rawText,
        doctorComment,
        medicines: validMedicines.map((medicine) => ({
          ...medicine,
          quantityNeeded: Number(medicine.quantityNeeded || 1)
        }))
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
    <div className="prescription-editor-layout">
      <aside className="section-band patient-panel editor-patient-panel">
        <div className="patient-profile-card">
          <div className="patient-avatar">
            <UserRound size={24} />
          </div>
          <div>
            <span>Пациент</span>
            <strong>{appointment.patient.fullName}</strong>
          </div>
        </div>
        <div className="patient-info-list">
          <div>
            <span>Телефон</span>
            <strong>{appointment.patient.phone}</strong>
          </div>
          <div>
            <span>Клиника</span>
            <strong>{appointment.clinic.name}</strong>
          </div>
          <div>
            <span>Дата приема</span>
            <strong>{new Date(appointment.appointmentDate).toLocaleString("ru-RU")}</strong>
          </div>
        </div>
        <div className="complaint-card">
          <span>Жалоба</span>
          <p>{appointment.complaint}</p>
        </div>
        <div className="editor-preview doctor-safety-preview">
          <div>
            <ClipboardList size={18} />
            Врач заполняет лечение. AI только структурирует и объясняет пациенту.
          </div>
        </div>
      </aside>

      <section className="section-band prescription-editor">
        <div className="section-header">
          <div>
            <h2>Создать цифровое назначение</h2>
            <p>Заполните диагноз, текст врача и список препаратов для пациента</p>
          </div>
          <button className="secondary-button" onClick={onCancel}>
            <X size={18} />
            Закрыть
          </button>
        </div>

        <div className="template-strip">
          {templates.map((template) => (
            <button key={template.label} type="button" onClick={() => applyTemplate(template)}>
              <FileText size={16} />
              {template.label}
            </button>
          ))}
        </div>

        <form className="form prescription-form" onSubmit={handleSubmit}>
          <div className="form-grid">
            <label>
              Appointment ID
              <input value={appointment.id} disabled />
            </label>
            <label>
              Диагноз
              <input value={diagnosis} onChange={(event) => setDiagnosis(event.target.value)} />
            </label>
          </div>

          <label>
            Текст назначения врача
            <div className="textarea-header-actions">
              <button
                type="button"
                className="ai-check-button"
                onClick={handleAiCheck}
                disabled={validating || !rawText.trim()}
              >
                {validating ? (
                  "Проверяем..."
                ) : (
                  <>
                    <Sparkles size={16} />
                    Проверить через ИИ
                  </>
                )}
              </button>
            </div>
            <textarea value={rawText} onChange={(event) => setRawText(event.target.value)} rows={6} />
          </label>

          {aiCheckResult && (
            <div className={`ai-validation-box ${aiCheckResult.isComplete ? "complete" : "incomplete"}`}>
              <div className="validation-header">
                {aiCheckResult.isComplete ? <Plus size={18} /> : <FileText size={18} />}
                <strong>{aiCheckResult.isComplete ? "Назначение заполнено корректно" : "Рекомендации ИИ по заполнению"}</strong>
              </div>
              
              {aiCheckResult.warnings.length > 0 && (
                <ul className="validation-warnings">
                  {aiCheckResult.warnings.map((w, i) => <li key={i}>{w}</li>)}
                </ul>
              )}
              
              {aiCheckResult.suggestions.length > 0 && (
                <div className="validation-suggestions">
                  <strong>Что уточнить:</strong>
                  <ul>
                    {aiCheckResult.suggestions.map((s, i) => <li key={i}>{s}</li>)}
                  </ul>
                </div>
              )}
            </div>
          )}

          <label>
            Комментарий врача
            <textarea value={doctorComment} onChange={(event) => setDoctorComment(event.target.value)} rows={3} />
          </label>

          <div className="medicine-editor-block">
            <div className="medicine-editor-head">
              <div>
                <h3>Препараты и лечение</h3>
                <p>Эти данные сохраняются в назначении и используются для маркета и графика приема.</p>
              </div>
              <button type="button" className="secondary-button" onClick={addMedicine}>
                <Plus size={18} />
                Добавить
              </button>
            </div>

            <div className="medicine-editor-list">
              {medicines.map((medicine, index) => (
                <article className="medicine-editor-card" key={`${medicine.medicineName}-${index}`}>
                  <div className="medicine-editor-card-head">
                    <div className="document-icon">
                      <Pill size={18} />
                    </div>
                    <strong>Препарат {index + 1}</strong>
                    <button type="button" className="icon-button" onClick={() => removeMedicine(index)} title="Удалить препарат">
                      <Trash2 size={17} />
                    </button>
                  </div>
                  <div className="medicine-form-grid">
                    <label>
                      Название
                      <input value={medicine.medicineName} onChange={(event) => updateMedicine(index, { medicineName: event.target.value })} />
                    </label>
                    <label>
                      Дозировка
                      <input value={medicine.dosage} onChange={(event) => updateMedicine(index, { dosage: event.target.value })} />
                    </label>
                    <label>
                      Частота
                      <input value={medicine.frequency} onChange={(event) => updateMedicine(index, { frequency: event.target.value })} />
                    </label>
                    <label>
                      Длительность
                      <input value={medicine.duration} onChange={(event) => updateMedicine(index, { duration: event.target.value })} />
                    </label>
                    <label>
                      Количество на курс
                      <input
                        type="number"
                        min={1}
                        value={medicine.quantityNeeded}
                        onChange={(event) => updateMedicine(index, { quantityNeeded: Number(event.target.value || 1) })}
                      />
                    </label>
                    <label>
                      Active substance
                      <input value={medicine.activeSubstance} onChange={(event) => updateMedicine(index, { activeSubstance: event.target.value })} />
                    </label>
                    <label className="wide-field">
                      Инструкция
                      <textarea value={medicine.instruction} onChange={(event) => updateMedicine(index, { instruction: event.target.value })} rows={2} />
                    </label>
                  </div>
                </article>
              ))}
            </div>
          </div>

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

          <div className="editor-preview">
            <div>
              <Sparkles size={18} />
              Пациент увидит сначала текст врача, затем AI-объяснение простым языком.
            </div>
            <div>
              <CalendarClock size={18} />
              После анализа создаются товары в аптеке и график приема.
            </div>
          </div>

          {error && <div className="error-text">{error}</div>}

          <div className="form-actions">
            <button className="secondary-button" type="button" onClick={onCancel}>
              Отмена
            </button>
            <button className="primary-button" disabled={loading}>
              <Send size={18} />
              {loading ? "Отправка..." : "Отправить назначение"}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
