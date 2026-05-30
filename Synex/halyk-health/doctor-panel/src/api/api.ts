export type UserRole = "PATIENT" | "DOCTOR" | "ADMIN" | "PHARMACY_ADMIN" | "PHARMACY_STAFF";
export type AppointmentStatus = "PENDING" | "CONFIRMED" | "RESCHEDULED" | "COMPLETED" | "CANCELLED";
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

// ─── Pharmacy Types ────────────────────────────────────────────────────────────

export type Pharmacy = {
  id: string;
  name: string;
  bin: string;
  address: string;
  city: string;
  phone: string;
  email: string;
  workingHours: string;
  deliveryEnabled: boolean;
  pickupEnabled: boolean;
  createdAt: string;
};

export type PharmacyProductForm = "TABLET" | "SYRUP" | "SPRAY" | "CAPSULE" | "DROPS" | "OINTMENT" | "INJECTION" | "OTHER";

export type PharmacyProduct = {
  id: string;
  pharmacyId: string;
  name: string;
  activeSubstance: string;
  dosage: string;
  form: PharmacyProductForm;
  category?: string;
  manufacturer?: string;
  price: number;
  stock: number;
  minStock: number;
  imageUrl?: string | null;
  isAvailable: boolean;
  requiresPrescription: boolean;
  description?: string;
  createdAt: string;
};

export type StockMovementReason = "SUPPLY" | "SALE" | "WRITE_OFF" | "CORRECTION";

export type PharmacyStockMovement = {
  id: string;
  productId: string;
  quantity: number;
  reason: StockMovementReason;
  comment?: string;
  createdBy: string;
  createdAt: string;
};

export type PharmacyOrderStatus =
  | "NEW"
  | "CONFIRMED"
  | "PREPARING"
  | "READY_FOR_PICKUP"
  | "DELIVERING"
  | "COMPLETED"
  | "CANCELLED"
  | "OUT_OF_STOCK";

export type PharmacyOrderItem = {
  id: string;
  orderId: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  isAvailable: boolean;
  product?: PharmacyProduct;
};

export type PharmacyOrder = {
  id: string;
  pharmacyId: string;
  patientName: string;
  patientPhone: string;
  totalPrice: number;
  deliveryType: "pickup" | "delivery";
  deliveryAddress?: string;
  status: PharmacyOrderStatus;
  comment?: string;
  createdAt: string;
  items: PharmacyOrderItem[];
};

export type PharmacyStaffEntry = {
  id: string;
  pharmacyId: string;
  userId: string;
  isActive: boolean;
  createdAt: string;
  user: {
    id: string;
    fullName: string;
    email: string;
    phone: string;
    role: UserRole;
  };
};

export type PharmacyDashboard = {
  pharmacy: Pharmacy;
  stats: {
    newOrders: number;
    processingOrders: number;
    lowStockProducts: number;
    totalProducts: number;
  };
  recentOrders: PharmacyOrder[];
};

// ─── API Layer ─────────────────────────────────────────────────────────────────

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
  // ─── Auth ────────────────────────────────────────────────────────────────
  async login(email: string, password: string) {
    return request<{ token: string; user: User }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password })
    });
  },
  me() {
    return request<User>("/auth/me");
  },

  // ─── Doctor ──────────────────────────────────────────────────────────────
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
    medicines?: Array<{
      medicineName: string;
      dosage: string;
      frequency: string;
      duration: string;
      instruction: string;
      quantityNeeded: number;
      activeSubstance: string;
    }>;
  }) {
    return request<Prescription>("/prescriptions", {
      method: "POST",
      body: JSON.stringify(payload)
    });
  },
  analyzePrescription(id: string) {
    return request<Prescription>(`/prescriptions/${id}/analyze-ai`, { method: "POST" });
  },
  validatePrescription(rawText: string) {
    return request<{ isComplete: boolean; warnings: string[]; suggestions: string[] }>("/ai/validate-prescription", {
      method: "POST",
      body: JSON.stringify({ rawText })
    });
  },
  getDemandReport() {
    return request<{
      frequentlyPrescribed: string[];
      cartLeaders: string[];
      outOfStockDemand: string[];
      popularAlternatives: string[];
      demandForecast: string;
      businessSummary: string;
    }>("/ai/demand-report");
  },
  doctorPrescriptions() {
    return request<Prescription[]>("/doctor/prescriptions");
  },

  // ─── Pharmacy Dashboard ──────────────────────────────────────────────────
  pharmacyDashboard() {
    return request<PharmacyDashboard>("/pharmacy/dashboard");
  },

  // ─── Pharmacy Profile ────────────────────────────────────────────────────
  pharmacyProfile() {
    return request<Pharmacy>("/pharmacy/me");
  },
  updatePharmacyProfile(data: Partial<Omit<Pharmacy, "id" | "createdAt">>) {
    return request<Pharmacy>("/pharmacy/me", {
      method: "PATCH",
      body: JSON.stringify(data)
    });
  },

  // ─── Pharmacy Products ───────────────────────────────────────────────────
  pharmacyProducts(params?: { search?: string; category?: string; stockStatus?: string }) {
    const qs = new URLSearchParams();
    if (params?.search) qs.set("search", params.search);
    if (params?.category) qs.set("category", params.category);
    if (params?.stockStatus) qs.set("stockStatus", params.stockStatus);
    return request<PharmacyProduct[]>(`/pharmacy/products${qs.toString() ? `?${qs}` : ""}`);
  },
  pharmacyProduct(id: string) {
    return request<PharmacyProduct>(`/pharmacy/products/${id}`);
  },
  createPharmacyProduct(data: Omit<PharmacyProduct, "id" | "pharmacyId" | "createdAt">) {
    return request<PharmacyProduct>("/pharmacy/products", {
      method: "POST",
      body: JSON.stringify(data)
    });
  },
  updatePharmacyProduct(id: string, data: Partial<Omit<PharmacyProduct, "id" | "pharmacyId" | "createdAt">>) {
    return request<PharmacyProduct>(`/pharmacy/products/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data)
    });
  },
  deletePharmacyProduct(id: string) {
    return request<{ success: boolean }>(`/pharmacy/products/${id}`, { method: "DELETE" });
  },

  // ─── Pharmacy Stock ──────────────────────────────────────────────────────
  updateStock(productId: string, quantity: number, reason: StockMovementReason, comment?: string) {
    return request<PharmacyProduct>(`/pharmacy/products/${productId}/stock`, {
      method: "PATCH",
      body: JSON.stringify({ quantity, reason, comment })
    });
  },
  stockMovements(productId: string) {
    return request<PharmacyStockMovement[]>(`/pharmacy/products/${productId}/stock-movements`);
  },

  // ─── Pharmacy Orders ─────────────────────────────────────────────────────
  pharmacyOrders(status?: string) {
    return request<PharmacyOrder[]>(`/pharmacy/orders${status ? `?status=${status}` : ""}`);
  },
  pharmacyOrder(id: string) {
    return request<PharmacyOrder>(`/pharmacy/orders/${id}`);
  },
  updateOrderStatus(id: string, status: PharmacyOrderStatus) {
    return request<PharmacyOrder>(`/pharmacy/orders/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ status })
    });
  },
  updateOrderItemAvailability(orderId: string, itemId: string, isAvailable: boolean) {
    return request<PharmacyOrderItem>(`/pharmacy/orders/${orderId}/item-availability`, {
      method: "PATCH",
      body: JSON.stringify({ itemId, isAvailable })
    });
  },
  orderAlternatives(orderId: string) {
    return request<Record<string, PharmacyProduct[]>>(`/pharmacy/orders/${orderId}/alternatives`);
  },

  // ─── Pharmacy Staff ──────────────────────────────────────────────────────
  pharmacyStaff() {
    return request<PharmacyStaffEntry[]>("/pharmacy/staff");
  },
  addPharmacyStaff(data: { fullName: string; email: string; phone: string; password: string; role: "PHARMACY_ADMIN" | "PHARMACY_STAFF" }) {
    return request<PharmacyStaffEntry>("/pharmacy/staff", {
      method: "POST",
      body: JSON.stringify(data)
    });
  },
  updatePharmacyStaff(id: string, data: { isActive?: boolean; role?: "PHARMACY_ADMIN" | "PHARMACY_STAFF" }) {
    return request<PharmacyStaffEntry>(`/pharmacy/staff/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data)
    });
  },
  removePharmacyStaff(id: string) {
    return request<{ success: boolean }>(`/pharmacy/staff/${id}`, { method: "DELETE" });
  }
};
