import { Router } from "express";
import { AppointmentStatus, UserRole } from "@prisma/client";
import { z } from "zod";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { HttpError } from "../../common/http-error";
import { prisma } from "../../common/prisma";
import { validateBody } from "../../common/validation";

const router = Router();

const createAppointmentSchema = z.object({
  patientProfileId: z.string().uuid(),
  doctorId: z.string().uuid(),
  clinicId: z.string().uuid(),
  appointmentDate: z.string().datetime(),
  complaint: z.string().min(3)
});

const updateStatusSchema = z.object({
  status: z.nativeEnum(AppointmentStatus)
});

const rescheduleSchema = z.object({
  appointmentDate: z.string().datetime()
});

const appointmentInclude = {
  patientProfile: {
    include: {
      user: {
        select: {
          id: true,
          fullName: true,
          email: true,
          phone: true
        }
      }
    }
  },
  doctor: {
    select: {
      id: true,
      fullName: true,
      email: true,
      phone: true,
      role: true,
      doctorProfile: {
        select: {
          specialization: true,
          roomNumber: true
        }
      }
    }
  },
  clinic: true,
  prescription: { select: { id: true } }
};

// POST /api/appointments — create new appointment (PATIENT)
router.post(
  "/",
  authenticate,
  requireRole(UserRole.PATIENT),
  validateBody(createAppointmentSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);

    const profile = await prisma.patientProfile.findFirst({
      where: { id: req.body.patientProfileId, userId: auth.userId }
    });

    if (!profile) {
      throw new HttpError(404, "Patient profile not found");
    }

    const doctor = await prisma.user.findUnique({
      where: { id: req.body.doctorId },
      include: { doctorProfile: true }
    });

    if (!doctor || doctor.role !== UserRole.DOCTOR) {
      throw new HttpError(404, "Doctor not found");
    }

    if (doctor.doctorProfile?.clinicId !== req.body.clinicId) {
      throw new HttpError(400, "Doctor does not belong to selected clinic");
    }

    const appointment = await prisma.appointment.create({
      data: {
        patientProfileId: req.body.patientProfileId,
        doctorId: req.body.doctorId,
        clinicId: req.body.clinicId,
        appointmentDate: new Date(req.body.appointmentDate),
        complaint: req.body.complaint
      },
      include: appointmentInclude
    });

    res.status(201).json(appointment);
  })
);

// GET /api/appointments/my — get current user's family appointments
router.get(
  "/my",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const { patientProfileId } = req.query;

    const appointments = await prisma.appointment.findMany({
      where: {
        patientProfile: {
          userId: auth.userId,
          ...(patientProfileId ? { id: patientProfileId as string } : {})
        }
      },
      include: appointmentInclude,
      orderBy: { appointmentDate: "desc" }
    });

    res.json(appointments);
  })
);

// GET /api/appointments/doctor — get appointments for doctor/admin
router.get(
  "/doctor",
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

// PATCH /api/appointments/:id/status — doctor/admin updates status
router.patch(
  "/:id/status",
  authenticate,
  requireRole(UserRole.DOCTOR, UserRole.ADMIN),
  validateBody(updateStatusSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const appointment = await prisma.appointment.findUnique({
      where: { id: req.params.id }
    });

    if (!appointment) {
      throw new HttpError(404, "Appointment not found");
    }

    if (auth.role === UserRole.DOCTOR && appointment.doctorId !== auth.userId) {
      throw new HttpError(403, "Doctor can update only own appointments");
    }

    const updatedAppointment = await prisma.appointment.update({
      where: { id: req.params.id },
      data: { status: req.body.status },
      include: appointmentInclude
    });

    res.json(updatedAppointment);
  })
);

// PATCH /api/appointments/:id/cancel — patient cancels own family appointment
router.patch(
  "/:id/cancel",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const appointment = await prisma.appointment.findUnique({
      where: { id: req.params.id },
      include: { patientProfile: true }
    });

    if (!appointment) {
      throw new HttpError(404, "Appointment not found");
    }

    if (appointment.patientProfile.userId !== auth.userId) {
      throw new HttpError(403, "You can only cancel your own family appointments");
    }

    if (appointment.status === AppointmentStatus.COMPLETED || appointment.status === AppointmentStatus.CANCELLED) {
      throw new HttpError(400, "Cannot cancel a completed or already cancelled appointment");
    }

    const updatedAppointment = await prisma.appointment.update({
      where: { id: req.params.id },
      data: { status: AppointmentStatus.CANCELLED },
      include: appointmentInclude
    });

    res.json(updatedAppointment);
  })
);

// PATCH /api/appointments/:id/reschedule — patient reschedules own family appointment
router.patch(
  "/:id/reschedule",
  authenticate,
  requireRole(UserRole.PATIENT),
  validateBody(rescheduleSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const appointment = await prisma.appointment.findUnique({
      where: { id: req.params.id },
      include: { patientProfile: true }
    });

    if (!appointment) {
      throw new HttpError(404, "Appointment not found");
    }

    if (appointment.patientProfile.userId !== auth.userId) {
      throw new HttpError(403, "You can only reschedule your own family appointments");
    }

    if (
      appointment.status === AppointmentStatus.COMPLETED ||
      appointment.status === AppointmentStatus.CANCELLED
    ) {
      throw new HttpError(400, "Cannot reschedule a completed or cancelled appointment");
    }

    const updatedAppointment = await prisma.appointment.update({
      where: { id: req.params.id },
      data: {
        appointmentDate: new Date(req.body.appointmentDate),
        status: AppointmentStatus.RESCHEDULED
      },
      include: appointmentInclude
    });

    res.json(updatedAppointment);
  })
);

export default router;
