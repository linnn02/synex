import { Router } from "express";
import { Prisma, UserRole } from "@prisma/client";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { prisma } from "../../common/prisma";

const router = Router();

const appointmentInclude = {
  patient: { select: { id: true, fullName: true, email: true, phone: true } },
  doctor: { select: { id: true, fullName: true, email: true, phone: true } },
  clinic: true,
  prescription: true
} satisfies Prisma.AppointmentInclude;

const prescriptionInclude = {
  appointment: {
    include: {
      clinic: true,
      patient: { select: { id: true, fullName: true, email: true, phone: true } },
      doctor: { select: { id: true, fullName: true, email: true, phone: true } }
    }
  },
  patient: { select: { id: true, fullName: true, email: true, phone: true } },
  doctor: { select: { id: true, fullName: true, email: true, phone: true } },
  medicines: {
    include: {
      matches: { include: { product: true } },
      schedules: { orderBy: { takeTime: "asc" } }
    }
  }
} satisfies Prisma.PrescriptionInclude;

router.get(
  "/appointments",
  authenticate,
  requireRole(UserRole.DOCTOR, UserRole.ADMIN),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);

    const appointments = await prisma.appointment.findMany({
      where: auth.role === UserRole.DOCTOR ? { doctorId: auth.userId } : undefined,
      include: appointmentInclude,
      orderBy: [{ status: "asc" }, { appointmentDate: "asc" }]
    });

    res.json(appointments);
  })
);

router.get(
  "/prescriptions",
  authenticate,
  requireRole(UserRole.DOCTOR, UserRole.ADMIN),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);

    const prescriptions = await prisma.prescription.findMany({
      where: auth.role === UserRole.DOCTOR ? { doctorId: auth.userId } : undefined,
      include: prescriptionInclude,
      orderBy: { createdAt: "desc" }
    });

    res.json(prescriptions);
  })
);

export default router;
