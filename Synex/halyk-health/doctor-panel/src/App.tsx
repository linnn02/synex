import { useEffect, useState } from "react";
import type { Appointment, AppointmentStatus, Prescription, User } from "./api/api";
import { api, clearToken, getToken, setToken } from "./api/api";
import { AppShell } from "./components/AppShell";
import { PharmacyAppShell, type PharmacyView } from "./components/PharmacyAppShell";
import { AppointmentsPage } from "./pages/AppointmentsPage";
import { CreatePrescriptionPage } from "./pages/CreatePrescriptionPage";
import { DoctorDashboard } from "./pages/DoctorDashboard";
import { LoginPage } from "./pages/LoginPage";
import { PrescriptionsPage } from "./pages/PrescriptionsPage";
import { DemandReportPage } from "./pages/DemandReportPage";
import { PharmacyDashboardPage } from "./pages/pharmacy/PharmacyDashboardPage";
import { PharmacyProductsPage } from "./pages/pharmacy/PharmacyProductsPage";
import { PharmacyProductFormPage } from "./pages/pharmacy/PharmacyProductFormPage";
import { PharmacyStockPage } from "./pages/pharmacy/PharmacyStockPage";
import { PharmacyOrdersPage } from "./pages/pharmacy/PharmacyOrdersPage";
import { PharmacyOrderDetailPage } from "./pages/pharmacy/PharmacyOrderDetailPage";
import { PharmacyStaffPage } from "./pages/pharmacy/PharmacyStaffPage";
import { PharmacyProfilePage } from "./pages/pharmacy/PharmacyProfilePage";
import { PharmacySettingsPage } from "./pages/pharmacy/PharmacySettingsPage";

type DoctorView = "dashboard" | "appointments" | "prescriptions" | "demand";

function isPharmacyUser(user: User) {
  return user.role === "PHARMACY_ADMIN" || user.role === "PHARMACY_STAFF";
}

// ─── Pharmacy App ─────────────────────────────────────────────────────────────

function PharmacyApp({ user, onLogout }: { user: User; onLogout: () => void }) {
  const [view, setView] = useState<PharmacyView>("dashboard");
  const [pharmacyName, setPharmacyName] = useState("Аптека");
  const [newOrdersCount, setNewOrdersCount] = useState(0);

  useEffect(() => {
    api.pharmacyDashboard().then((d) => {
      setPharmacyName(d.pharmacy.name);
      setNewOrdersCount(d.stats.newOrders);
    }).catch(() => {});
  }, [view]);

  function navigate(target: string) {
    setView(target as PharmacyView);
  }

  function renderContent() {
    if (view === "dashboard") {
      return <PharmacyDashboardPage onNavigate={navigate} />;
    }
    if (view === "products") {
      return <PharmacyProductsPage onNavigate={navigate} />;
    }
    if (view === "products-add") {
      return (
        <PharmacyProductFormPage
          onCancel={() => setView("products")}
          onSaved={() => setView("products")}
        />
      );
    }
    if (view.startsWith("products-edit-")) {
      const productId = view.replace("products-edit-", "");
      return (
        <PharmacyProductFormPage
          productId={productId}
          onCancel={() => setView("products")}
          onSaved={() => setView("products")}
        />
      );
    }
    if (view === "stock") {
      return <PharmacyStockPage />;
    }
    if (view === "orders") {
      return <PharmacyOrdersPage onOpenOrder={(id) => setView(`order-${id}` as PharmacyView)} />;
    }
    if (view.startsWith("order-")) {
      const orderId = view.replace("order-", "");
      return (
        <PharmacyOrderDetailPage
          orderId={orderId}
          onBack={() => setView("orders")}
        />
      );
    }
    if (view === "staff") {
      return <PharmacyStaffPage />;
    }
    if (view === "profile") {
      return <PharmacyProfilePage />;
    }
    if (view === "settings") {
      return <PharmacySettingsPage onLogout={onLogout} />;
    }
    return <PharmacyDashboardPage onNavigate={navigate} />;
  }

  return (
    <PharmacyAppShell
      user={user}
      view={view}
      pharmacyName={pharmacyName}
      newOrdersCount={newOrdersCount}
      onViewChange={setView}
      onLogout={onLogout}
    >
      {renderContent()}
    </PharmacyAppShell>
  );
}

// ─── Doctor App ───────────────────────────────────────────────────────────────

function DoctorApp({ user, onLogout }: { user: User; onLogout: () => void }) {
  const [view, setView] = useState<DoctorView>("dashboard");
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [prescriptions, setPrescriptions] = useState<Prescription[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedAppointment, setSelectedAppointment] = useState<Appointment | null>(null);

  const pendingCount = appointments.filter((a) => a.status === "PENDING").length;
  const prescriptionsCount = prescriptions.length;
  const todayCount = appointments.filter((a) => {
    const date = new Date(a.appointmentDate);
    return date.toDateString() === new Date().toDateString();
  }).length;

  async function loadDoctorData() {
    setLoading(true);
    try {
      const [nextAppointments, nextPrescriptions] = await Promise.all([
        api.doctorAppointments(),
        api.doctorPrescriptions()
      ]);
      setAppointments(nextAppointments);
      setPrescriptions(nextPrescriptions);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadDoctorData(); }, []);

  async function handleStatusChange(id: string, status: AppointmentStatus) {
    await api.updateAppointmentStatus(id, status);
    await loadDoctorData();
  }

  async function handleAnalyze(id: string) {
    await api.analyzePrescription(id);
    await loadDoctorData();
  }

  function renderContent() {
    if (selectedAppointment) {
      return (
        <CreatePrescriptionPage
          appointment={selectedAppointment}
          onCancel={() => setSelectedAppointment(null)}
          onCreated={() => {
            setSelectedAppointment(null);
            setView("prescriptions");
            loadDoctorData();
          }}
        />
      );
    }
    if (view === "appointments") {
      return (
        <AppointmentsPage
          appointments={appointments}
          loading={loading}
          onRefresh={loadDoctorData}
          onStatusChange={handleStatusChange}
          onCreatePrescription={setSelectedAppointment}
        />
      );
    }
    if (view === "prescriptions") {
      return (
        <PrescriptionsPage
          prescriptions={prescriptions}
          loading={loading}
          onRefresh={loadDoctorData}
          onAnalyze={handleAnalyze}
        />
      );
    }
    if (view === "demand") {
      return <DemandReportPage />;
    }
    return (
      <DoctorDashboard
        appointments={appointments}
        prescriptions={prescriptions}
        onStatusChange={handleStatusChange}
        onCreatePrescription={setSelectedAppointment}
        onOpenAppointments={() => setView("appointments")}
        onOpenPrescriptions={() => setView("prescriptions")}
      />
    );
  }

  return (
    <AppShell
      user={user}
      view={view}
      loading={loading}
      pendingCount={pendingCount}
      todayCount={todayCount}
      prescriptionsCount={prescriptionsCount}
      onViewChange={setView}
      onRefresh={loadDoctorData}
      onLogout={onLogout}
    >
      {renderContent()}
    </AppShell>
  );
}

// ─── Root App ─────────────────────────────────────────────────────────────────

export function App() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    if (!getToken()) return;
    api.me()
      .then(setUser)
      .catch(() => { clearToken(); setUser(null); });
  }, []);

  async function handleLogin(email: string, password: string) {
    const result = await api.login(email, password);
    setToken(result.token);
    setUser(result.user);
  }

  function handleLogout() {
    clearToken();
    setUser(null);
  }

  if (!user) return <LoginPage onLogin={handleLogin} />;

  if (isPharmacyUser(user)) {
    return <PharmacyApp user={user} onLogout={handleLogout} />;
  }

  return <DoctorApp user={user} onLogout={handleLogout} />;
}
