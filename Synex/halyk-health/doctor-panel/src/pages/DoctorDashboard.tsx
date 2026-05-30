import { CalendarCheck, Clock3, FileText } from "lucide-react";
import type { Appointment, Prescription } from "../api/api";
import { StatCard } from "../components/StatCard";
import { StatusBadge } from "../components/StatusBadge";

type DoctorDashboardProps = {
  appointments: Appointment[];
  prescriptions: Prescription[];
  onOpenAppointments: () => void;
  onOpenPrescriptions: () => void;
};

export function DoctorDashboard({
  appointments,
  prescriptions,
  onOpenAppointments,
  onOpenPrescriptions
}: DoctorDashboardProps) {
  const pending = appointments.filter((item) => item.status === "PENDING").length;
  const confirmed = appointments.filter((item) => item.status === "CONFIRMED").length;

  return (
    <div className="content-stack">
      <section className="stats-grid">
        <StatCard label="Новые заявки" value={pending} tone="amber" icon={<Clock3 size={20} />} />
        <StatCard label="Подтверждённые записи" value={confirmed} tone="green" icon={<CalendarCheck size={20} />} />
        <StatCard label="Созданные назначения" value={prescriptions.length} icon={<FileText size={20} />} />
      </section>

      <section className="section-band">
        <div className="section-header">
          <h2>Ближайшие заявки</h2>
          <button className="secondary-button" onClick={onOpenAppointments}>
            <CalendarCheck size={18} />
            Открыть
          </button>
        </div>
        <div className="compact-list">
          {appointments.slice(0, 4).map((appointment) => (
            <article key={appointment.id} className="list-row">
              <div>
                <strong>{appointment.patient.fullName}</strong>
                <span>{new Date(appointment.appointmentDate).toLocaleString("ru-RU")}</span>
              </div>
              <StatusBadge status={appointment.status} />
            </article>
          ))}
          {!appointments.length && <p className="empty-text">Заявок пока нет.</p>}
        </div>
      </section>

      <section className="section-band">
        <div className="section-header">
          <h2>Последние назначения</h2>
          <button className="secondary-button" onClick={onOpenPrescriptions}>
            <FileText size={18} />
            Открыть
          </button>
        </div>
        <div className="compact-list">
          {prescriptions.slice(0, 4).map((prescription) => (
            <article key={prescription.id} className="list-row">
              <div>
                <strong>{prescription.patient.fullName}</strong>
                <span>{prescription.diagnosis}</span>
              </div>
              <StatusBadge status={prescription.status} />
            </article>
          ))}
          {!prescriptions.length && <p className="empty-text">Назначений пока нет.</p>}
        </div>
      </section>
    </div>
  );
}

