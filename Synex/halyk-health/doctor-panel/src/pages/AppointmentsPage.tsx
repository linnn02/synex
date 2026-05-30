import { Check, ClipboardPlus, Filter, Phone, RefreshCcw, Search, UserRound, X } from "lucide-react";
import { useMemo, useState } from "react";
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
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<AppointmentStatus | "ALL">("ALL");
  const [selectedAppointmentId, setSelectedAppointmentId] = useState<string | null>(appointments[0]?.id ?? null);

  const filteredAppointments = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    return appointments.filter((appointment) => {
      const statusMatches = status === "ALL" || appointment.status === status;
      const queryMatches =
        !normalizedQuery ||
        appointment.patient.fullName.toLowerCase().includes(normalizedQuery) ||
        appointment.patient.phone.toLowerCase().includes(normalizedQuery) ||
        appointment.complaint.toLowerCase().includes(normalizedQuery) ||
        appointment.clinic.name.toLowerCase().includes(normalizedQuery);

      return statusMatches && queryMatches;
    });
  }, [appointments, query, status]);

  const selectedAppointment =
    filteredAppointments.find((appointment) => appointment.id === selectedAppointmentId) ?? filteredAppointments[0];

  const statusCounters = {
    ALL: appointments.length,
    PENDING: appointments.filter((item) => item.status === "PENDING").length,
    CONFIRMED: appointments.filter((item) => item.status === "CONFIRMED").length,
    RESCHEDULED: appointments.filter((item) => item.status === "RESCHEDULED").length,
    COMPLETED: appointments.filter((item) => item.status === "COMPLETED").length,
    CANCELLED: appointments.filter((item) => item.status === "CANCELLED").length
  };

  return (
    <div className="content-stack">
      <section className="crm-toolbar">
        <div className="search-field">
          <Search size={18} />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Поиск по пациенту, телефону, жалобе или клинике"
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
            ["PENDING", "Новые"],
            ["CONFIRMED", "Подтвержденные"],
            ["RESCHEDULED", "Перенесенные"],
            ["COMPLETED", "Завершенные"],
            ["CANCELLED", "Отмененные"]
          ] as Array<[AppointmentStatus | "ALL", string]>
        ).map(([value, label]) => (
          <button key={value} className={status === value ? "active" : ""} onClick={() => setStatus(value)}>
            <Filter size={15} />
            {label}
            <span>{statusCounters[value]}</span>
          </button>
        ))}
      </section>

      <div className="appointments-crm-layout">
        <section className="section-band">
          <div className="section-header">
            <div>
              <h2>Заявки пациентов</h2>
              <p>{filteredAppointments.length} заявок в текущем фильтре</p>
            </div>
          </div>

          <div className="table-wrap">
            <table className="crm-table">
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
                {filteredAppointments.map((appointment) => (
                  <tr
                    key={appointment.id}
                    className={selectedAppointment?.id === appointment.id ? "selected-row" : ""}
                    onClick={() => setSelectedAppointmentId(appointment.id)}
                  >
                    <td data-label="Пациент">
                      <strong>{appointment.patient.fullName}</strong>
                      <span>{appointment.patient.phone}</span>
                    </td>
                    <td data-label="Дата">
                      <strong>{new Date(appointment.appointmentDate).toLocaleDateString("ru-RU")}</strong>
                      <span>
                        {new Date(appointment.appointmentDate).toLocaleTimeString("ru-RU", {
                          hour: "2-digit",
                          minute: "2-digit"
                        })}
                      </span>
                    </td>
                    <td data-label="Жалоба">{appointment.complaint}</td>
                    <td data-label="Статус">
                      <StatusBadge status={appointment.status} />
                    </td>
                    <td data-label="Действия">
                      <div className="action-row" onClick={(event) => event.stopPropagation()}>
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
            {!filteredAppointments.length && <p className="empty-text">Нет заявок по выбранным фильтрам.</p>}
          </div>
        </section>

        <aside className="patient-panel">
          {selectedAppointment ? (
            <>
              <div className="patient-profile-card">
                <div className="patient-avatar">
                  <UserRound size={24} />
                </div>
                <div>
                  <span>Пациент</span>
                  <strong>{selectedAppointment.patient.fullName}</strong>
                </div>
                <StatusBadge status={selectedAppointment.status} />
              </div>

              <div className="patient-info-list">
                <div>
                  <span>Телефон</span>
                  <strong>{selectedAppointment.patient.phone}</strong>
                </div>
                <div>
                  <span>Email</span>
                  <strong>{selectedAppointment.patient.email}</strong>
                </div>
                <div>
                  <span>Клиника</span>
                  <strong>{selectedAppointment.clinic.name}</strong>
                </div>
                <div>
                  <span>Адрес</span>
                  <strong>{selectedAppointment.clinic.address}</strong>
                </div>
              </div>

              <div className="complaint-card">
                <span>Причина обращения</span>
                <p>{selectedAppointment.complaint}</p>
              </div>

              <div className="panel-actions">
                <button className="secondary-button">
                  <Phone size={18} />
                  Позвонить
                </button>
                <button className="primary-button" onClick={() => onCreatePrescription(selectedAppointment)}>
                  <ClipboardPlus size={18} />
                  Назначение
                </button>
              </div>
            </>
          ) : (
            <p className="empty-text">Выберите заявку, чтобы открыть карточку пациента.</p>
          )}
        </aside>
      </div>
    </div>
  );
}
