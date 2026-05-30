import { Check, ClipboardPlus, RefreshCcw, X } from "lucide-react";
import type { Appointment, AppointmentStatus } from "../api/api";
import { StatusBadge } from "../components/StatusBadge";

type AppointmentsPageProps = {
  appointments: Appointment[];
  loading: boolean;
  onRefresh: () => void;
  onStatusChange: (id: string, status: AppointmentStatus) => Promise<void>;
  onCreatePrescription: (appointment: Appointment) => void;
};

export function AppointmentsPage({
  appointments,
  loading,
  onRefresh,
  onStatusChange,
  onCreatePrescription
}: AppointmentsPageProps) {
  return (
    <section className="section-band">
      <div className="section-header">
        <h2>Заявки пациентов</h2>
        <button className="secondary-button" onClick={onRefresh} disabled={loading}>
          <RefreshCcw size={18} />
          Обновить
        </button>
      </div>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Пациент</th>
              <th>Дата</th>
              <th>Жалоба</th>
              <th>Статус</th>
              <th>Действия</th>
            </tr>
          </thead>
          <tbody>
            {appointments.map((appointment) => (
              <tr key={appointment.id}>
                <td>
                  <strong>{appointment.patient.fullName}</strong>
                  <span>{appointment.patient.phone}</span>
                </td>
                <td>{new Date(appointment.appointmentDate).toLocaleString("ru-RU")}</td>
                <td>{appointment.complaint}</td>
                <td>
                  <StatusBadge status={appointment.status} />
                </td>
                <td>
                  <div className="action-row">
                    <button title="Подтвердить" onClick={() => onStatusChange(appointment.id, "CONFIRMED")}>
                      <Check size={17} />
                    </button>
                    <button title="Завершить" onClick={() => onStatusChange(appointment.id, "COMPLETED")}>
                      <Check size={17} />
                    </button>
                    <button title="Отменить" onClick={() => onStatusChange(appointment.id, "CANCELLED")}>
                      <X size={17} />
                    </button>
                    <button title="Создать назначение" onClick={() => onCreatePrescription(appointment)}>
                      <ClipboardPlus size={17} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!appointments.length && <p className="empty-text">Нет заявок для отображения.</p>}
      </div>
    </section>
  );
}

