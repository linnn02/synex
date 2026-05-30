import type { AppointmentStatus, PrescriptionStatus } from "../api/api";

type StatusBadgeProps = {
  status: AppointmentStatus | PrescriptionStatus;
};

const labels: Record<string, string> = {
  PENDING: "Новая",
  CONFIRMED: "Подтверждена",
  COMPLETED: "Завершена",
  CANCELLED: "Отменена",
  DRAFT: "Черновик",
  SENT: "Отправлено",
  ACTIVE: "Активно"
};

export function StatusBadge({ status }: StatusBadgeProps) {
  return <span className={`status-badge ${status.toLowerCase()}`}>{labels[status] || status}</span>;
}

