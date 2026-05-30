import {
  ArrowRight,
  CalendarCheck,
  CheckCircle2,
  Clock3,
  ClipboardPlus,
  FileText,
  Stethoscope,
  TrendingUp,
  UserRoundCheck,
  XCircle
} from "lucide-react";
import type { Appointment, AppointmentStatus, Prescription } from "../api/api";
import { StatCard } from "../components/StatCard";
import { StatusBadge } from "../components/StatusBadge";

type DoctorDashboardProps = {
  appointments: Appointment[];
  prescriptions: Prescription[];
  onStatusChange: (id: string, status: AppointmentStatus) => Promise<void>;
  onCreatePrescription: (appointment: Appointment) => void;
  onOpenAppointments: () => void;
  onOpenPrescriptions: () => void;
};

export function DoctorDashboard({
  appointments,
  prescriptions,
  onStatusChange,
  onCreatePrescription,
  onOpenAppointments,
  onOpenPrescriptions
}: DoctorDashboardProps) {
  const pending = appointments.filter((item) => item.status === "PENDING").length;
  const confirmed = appointments.filter((item) => item.status === "CONFIRMED" || item.status === "RESCHEDULED").length;
  const completed = appointments.filter((item) => item.status === "COMPLETED").length;
  const activePrescriptions = prescriptions.filter((item) => item.status === "ACTIVE" || item.status === "SENT").length;
  const queue = [...appointments]
    .sort((a, b) => new Date(a.appointmentDate).getTime() - new Date(b.appointmentDate).getTime())
    .slice(0, 5);
  const latestPrescription = prescriptions[0];

  return (
    <div className="content-stack">
      <section className="stats-grid">
        <StatCard label="Новые заявки" value={pending} detail="Ожидают реакции" tone="amber" icon={<Clock3 size={20} />} />
        <StatCard
          label="Подтверждено"
          value={confirmed}
          detail="Готовы к приему"
          tone="green"
          icon={<CalendarCheck size={20} />}
        />
        <StatCard label="Завершено" value={completed} detail="Визиты закрыты" icon={<CheckCircle2 size={20} />} />
        <StatCard
          label="Назначения"
          value={activePrescriptions}
          detail="Отправлены пациентам"
          tone="blue"
          icon={<FileText size={20} />}
        />
      </section>

      <section className="crm-grid">
        <div className="section-band queue-panel">
          <div className="section-header">
            <div>
              <h2>Рабочая очередь</h2>
              <p>Быстрые действия по заявкам пациента</p>
            </div>
            <button className="secondary-button" onClick={onOpenAppointments}>
              Все заявки
              <ArrowRight size={18} />
            </button>
          </div>
          <div className="queue-list">
            {queue.map((appointment) => (
              <article key={appointment.id} className="queue-card">
                <div className="queue-time">
                  <strong>
                    {new Date(appointment.appointmentDate).toLocaleTimeString("ru-RU", {
                      hour: "2-digit",
                      minute: "2-digit"
                    })}
                  </strong>
                  <span>
                    {new Date(appointment.appointmentDate).toLocaleDateString("ru-RU", {
                      day: "2-digit",
                      month: "short"
                    })}
                  </span>
                </div>
                <div className="queue-body">
                  <div className="queue-head">
                    <div>
                      <strong>{appointment.patient.fullName}</strong>
                      <span>{appointment.complaint}</span>
                    </div>
                    <StatusBadge status={appointment.status} />
                  </div>
                  <div className="queue-actions">
                    <button onClick={() => onStatusChange(appointment.id, "CONFIRMED")}>
                      <UserRoundCheck size={16} />
                      Подтвердить
                    </button>
                    <button onClick={() => onStatusChange(appointment.id, "CANCELLED")}>
                      <XCircle size={16} />
                      Отменить
                    </button>
                    <button onClick={() => onCreatePrescription(appointment)}>
                      <ClipboardPlus size={16} />
                      Назначение
                    </button>
                  </div>
                </div>
              </article>
            ))}
            {!queue.length && <p className="empty-text">Очередь пуста.</p>}
          </div>
        </div>

        <aside className="crm-side">
          <section className="section-band">
            <div className="section-header">
              <div>
                <h2>Сводка смены</h2>
                <p>Операционный статус кабинета</p>
              </div>
            </div>
            <div className="shift-list">
              <div>
                <span>Нагрузка</span>
                <strong>{appointments.length ? Math.round((confirmed / appointments.length) * 100) : 0}%</strong>
              </div>
              <div>
                <span>Пациентов в CRM</span>
                <strong>{new Set(appointments.map((item) => item.patient.id)).size}</strong>
              </div>
              <div>
                <span>AI-анализов</span>
                <strong>{prescriptions.filter((item) => item.aiSummary).length}</strong>
              </div>
            </div>
          </section>

          <section className="section-band highlight-panel">
            <div className="highlight-icon">
              <TrendingUp size={22} />
            </div>
            <h2>CRM-ритм</h2>
            <p>Сначала обработайте новые заявки, затем завершите подтвержденные визиты и создайте цифровые назначения.</p>
            <button className="primary-button" onClick={onOpenAppointments}>
              Перейти к очереди
            </button>
          </section>
        </aside>
      </section>

      <section className="section-band">
        <div className="section-header">
          <div>
            <h2>Последние назначения</h2>
            <p>Документы, которые уже видит пациент</p>
          </div>
          <button className="secondary-button" onClick={onOpenPrescriptions}>
            <FileText size={18} />
            Открыть журнал
          </button>
        </div>
        <div className="prescription-preview-grid">
          {prescriptions.slice(0, 4).map((prescription) => (
            <article key={prescription.id} className="mini-prescription-card">
              <div className="mini-prescription-icon">
                <Stethoscope size={18} />
              </div>
              <div>
                <strong>{prescription.patient.fullName}</strong>
                <span>{prescription.diagnosis}</span>
              </div>
              <StatusBadge status={prescription.status} />
            </article>
          ))}
          {!prescriptions.length && <p className="empty-text">Назначений пока нет.</p>}
        </div>
        {latestPrescription?.aiSummary && <div className="ai-summary">{latestPrescription.aiSummary}</div>}
      </section>
    </div>
  );
}
