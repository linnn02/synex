import "dotenv/config";
import cors from "cors";
import express from "express";
import swaggerUi from "swagger-ui-express";
import aiRoutes from "./modules/ai/ai.routes";
import appointmentsRoutes from "./modules/appointments/appointments.routes";
import authRoutes from "./modules/auth/auth.routes";
import clinicsRoutes from "./modules/clinics/clinics.routes";
import doctorRoutes from "./modules/doctor/doctor.routes";
import marketRoutes from "./modules/market/market.routes";
import notificationsRoutes from "./modules/notifications/notifications.routes";
import prescriptionsRoutes from "./modules/prescriptions/prescriptions.routes";
import scheduleRoutes from "./modules/schedule/schedule.routes";
import usersRoutes from "./modules/users/users.routes";
import patientProfilesRoutes from "./modules/patient-profiles/patient-profiles.routes";
import pharmacyRoutes from "./modules/pharmacy/pharmacy.routes";
import { errorHandler, notFoundHandler } from "./common/error-handler";
import { prisma } from "./common/prisma";
import { swaggerDocument } from "./common/swagger";

const app = express();
const port = Number(process.env.PORT || 4000);

app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "halyk-health-backend" });
});

app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));
app.get("/api/openapi.json", (_req, res) => res.json(swaggerDocument));

app.use("/api/auth", authRoutes);
app.use("/api/users", usersRoutes);
app.use("/api/clinics", clinicsRoutes);
app.use("/api/appointments", appointmentsRoutes);
app.use("/api/doctor", doctorRoutes);
app.use("/api/prescriptions", prescriptionsRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/market", marketRoutes);
app.use("/api/schedule", scheduleRoutes);
app.use("/api/notifications", notificationsRoutes);
app.use("/api/patient-profiles", patientProfilesRoutes);
app.use("/api/pharmacy", pharmacyRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

async function bootstrap() {
  await prisma.$connect();

  app.listen(port, () => {
    console.log(`Halyk Health API is running on http://localhost:${port}`);
    console.log(`Swagger docs are available on http://localhost:${port}/api/docs`);
  });
}

bootstrap().catch((error) => {
  console.error("Failed to start Halyk Health API", error);
  process.exit(1);
});
