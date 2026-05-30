export type UserRole = "PATIENT" | "DOCTOR" | "ADMIN";
export type AppointmentStatus = "PENDING" | "CONFIRMED" | "COMPLETED" | "CANCELLED";
export type PrescriptionStatus = "DRAFT" | "SENT" | "ACTIVE" | "COMPLETED";

export type User = {
  id: string;
  fullName: string;
  phone: string;
  email: string;
  role: UserRole;
};

export type Clinic = {
  id: string;
  name: string;
  city: string;
  address: string;
};

export type Appointment = {
  id: string;
  appointmentDate: string;
  complaint: string;
  status: AppointmentStatus;
  patient: User;
  doctor: User;
  clinic: Clinic;
  prescription?: Prescription | null;
};

export type PrescriptionMedicine = {
  id: string;
  medicineName: string;
  dosage: string;
  frequency: string;
  duration: string;
  instruction: string;
  quantityNeeded: number;
  activeSubstance: string;
};

export type Prescription = {
  id: string;
  diagnosis: string;
  rawText: string;
  doctorComment?: string;
  aiSummary?: string;
  aiDisclaimer?: string;
  status: PrescriptionStatus;
  createdAt: string;
  appointment?: Appointment;
  patient: User;
  doctor: User;
  medicines: PrescriptionMedicine[];
};

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:4000/api";
const TOKEN_KEY = "halyk_health_doctor_token";

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers
    }
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: { message: response.statusText } }));
    throw new Error(error.error?.message || "API request failed");
  }

  return response.json();
}

export const api = {
  async login(email: string, password: string) {
    return request<{ token: string; user: User }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password })
    });
  },
  me() {
    return request<User>("/auth/me");
  },
  doctorAppointments() {
    return request<Appointment[]>("/doctor/appointments");
  },
  updateAppointmentStatus(id: string, status: AppointmentStatus) {
    return request<Appointment>(`/appointments/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ status })
    });
  },
  createPrescription(payload: {
    appointmentId: string;
    diagnosis: string;
    rawText: string;
    doctorComment?: string;
  }) {
    return request<Prescription>("/prescriptions", {
      method: "POST",
      body: JSON.stringify(payload)
    });
  },
  analyzePrescription(id: string) {
    return request<Prescription>(`/prescriptions/${id}/analyze-ai`, { method: "POST" });
  },
  doctorPrescriptions() {
    return request<Prescription[]>("/doctor/prescriptions");
  }
};

