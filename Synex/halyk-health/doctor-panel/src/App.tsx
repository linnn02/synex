import { useEffect, useMemo, useState } from "react";
import type { Appointment, AppointmentStatus, Prescription, User } from "./api/api";
import { api, clearToken, getToken, setToken } from "./api/api";
import { AppShell } from "./components/AppShell";
import { AppointmentsPage } from "./pages/AppointmentsPage";
import { CreatePrescriptionPage } from "./pages/CreatePrescriptionPage";
import { DoctorDashboard } from "./pages/DoctorDashboard";
import { LoginPage } from "./pages/LoginPage";
import { PrescriptionsPage } from "./pages/PrescriptionsPage";

type View = "dashboard" | "appointments" | "prescriptions";

export function App() {
  const [user, setUser] = useState<User | null>(null);
  const [view, setView] = useState<View>("dashboard");
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [prescriptions, setPrescriptions] = useState<Prescription[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedAppointment, setSelectedAppointment] = useState<Appointment | null>(null);

  const pendingCount = appointments.filter((item) => item.status === "PENDING").length;
  const prescriptionsCount = prescriptions.length;
  const todayCount = appointments.filter((item) => {
    const date = new Date(item.appointmentDate);
    const now = new Date();
    return date.toDateString() === now.toDateString();
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

  useEffect(() => {
    if (!getToken()) {
      return;
    }

    api
      .me()
      .then((currentUser) => {
        setUser(currentUser);
        return loadDoctorData();
      })
      .catch(() => {
        clearToken();
        setUser(null);
      });
  }, []);

  async function handleLogin(email: string, password: string) {
    const result = await api.login(email, password);
    setToken(result.token);
    setUser(result.user);
    await loadDoctorData();
  }

  async function handleStatusChange(id: string, status: AppointmentStatus) {
    await api.updateAppointmentStatus(id, status);
    await loadDoctorData();
  }

  async function handleAnalyze(id: string) {
    await api.analyzePrescription(id);
    await loadDoctorData();
  }

  function handleLogout() {
    clearToken();
    setUser(null);
    setAppointments([]);
    setPrescriptions([]);
  }

  const content = useMemo(() => {
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
  }, [appointments, loading, prescriptions, selectedAppointment, view]);

  if (!user) {
    return <LoginPage onLogin={handleLogin} />;
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
      onLogout={handleLogout}
    >
      {content}
    </AppShell>
  );
}
