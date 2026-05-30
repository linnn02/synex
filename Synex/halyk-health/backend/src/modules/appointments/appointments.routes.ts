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
  doctorId: z.string().uuid(),
  clinicId: z.string().uuid(),
  appointmentDate: z.string().datetime(),
  complaint: z.string().min(3)
});

const updateStatusSchema = z.object({
  status: z.nativeEnum(AppointmentStatus)
});

const appointmentInclude = {
  patient: { select: { id: true, fullName: true, email: true, phone: true } },
  doctor: { select: { id: true, fullName: true, email: true, phone: true } },
  clinic: true,
  prescription: true
};

router.post(
  "/",
  authenticate,
  requireRole(UserRole.PATIENT),
  validateBody(createAppointmentSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);

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
        patientId: auth.userId,
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

router.get(
  "/my",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);

    const appointments = await prisma.appointment.findMany({
      where: { patientId: auth.userId },
      include: appointmentInclude,
      orderBy: { appointmentDate: "desc" }
    });

    res.json(appointments);
  })
);

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

router.patch(
  "/:id/status",
  authenticate,
  requireRole(UserRole.DOCTOR, UserRole.ADMIN),
  validateBody(updateStatusSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const appointment = await prisma.appointment.findUnique({ where: { id: req.params.id } });

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

export default router;

