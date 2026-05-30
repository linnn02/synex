import type { ReactNode } from "react";

type StatCardProps = {
  label: string;
  value: string | number;
  icon: ReactNode;
  detail?: string;
  tone?: "blue" | "green" | "amber" | "red";
};

export function StatCard({ label, value, icon, detail, tone = "blue" }: StatCardProps) {
  return (
    <article className={`stat-card ${tone}`}>
      <div className="stat-card-top">
        <div className="stat-icon">{icon}</div>
        <span>{label}</span>
      </div>
      <strong>{value}</strong>
      {detail && <small>{detail}</small>}
    </article>
  );
}
