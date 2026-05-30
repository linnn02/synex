import { Router } from "express";
import { Prisma, UserRole } from "@prisma/client";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { prisma } from "../../common/prisma";

const router = Router();

const appointmentInclude = {
  patientProfile: {
    include: {
      user: { select: { id: true, fullName: true, email: true, phone: true, role: true } }
    }
  },
  doctor: { select: { id: true, fullName: true, email: true, phone: true } },
  clinic: true,
  prescription: true
} satisfies Prisma.AppointmentInclude;

const prescriptionInclude = {
  appointment: {
    include: {
      clinic: true,
      patientProfile: {
        include: {
          user: { select: { id: true, fullName: true, email: true, phone: true, role: true } }
        }
      },
      doctor: { select: { id: true, fullName: true, email: true, phone: true } }
    }
  },
  patientProfile: {
    include: {
      user: { select: { id: true, fullName: true, email: true, phone: true, role: true } }
    }
  },
  doctor: { select: { id: true, fullName: true, email: true, phone: true } },
  medicines: {
    include: {
      matches: { include: { product: true } },
      schedules: { orderBy: { takeTime: "asc" } }
    }
  }
} satisfies Prisma.PrescriptionInclude;

type AppointmentWithProfile = Prisma.AppointmentGetPayload<{ include: typeof appointmentInclude }>;
type PrescriptionWithProfile = Prisma.PrescriptionGetPayload<{ include: typeof prescriptionInclude }>;

function profileAsPatient(profile: AppointmentWithProfile["patientProfile"] | PrescriptionWithProfile["patientProfile"]) {
  return {
    id: profile.id,
    fullName: profile.fullName,
    email: profile.user.email,
    phone: profile.user.phone,
    role: profile.user.role,
    iin: profile.iin,
    relationType: profile.relationType,
    insuranceStatus: profile.insuranceStatus
  };
}

function serializeAppointment(appointment: AppointmentWithProfile) {
  return {
    ...appointment,
    patient: profileAsPatient(appointment.patientProfile)
  };
}

function serializePrescription(prescription: PrescriptionWithProfile) {
  return {
    ...prescription,
    patient: profileAsPatient(prescription.patientProfile),
    appointment: prescription.appointment
      ? {
          ...prescription.appointment,
          patient: profileAsPatient(prescription.appointment.patientProfile)
        }
      : prescription.appointment
  };
}

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

    res.json(appointments.map(serializeAppointment));
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

    res.json(prescriptions.map(serializePrescription));
  })
);

export default router;
