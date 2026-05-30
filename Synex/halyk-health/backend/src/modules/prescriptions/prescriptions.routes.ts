import { Router } from "express";
import { Prisma, UserRole } from "@prisma/client";
import { z } from "zod";
import { AI_DISCLAIMER } from "../../common/constants";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { HttpError } from "../../common/http-error";
import { prisma } from "../../common/prisma";
import { validateBody } from "../../common/validation";
import { parsePrescription } from "../ai/ai.service";
import { createMedicineMatches } from "../market/market.service";
import { createScheduleForMedicine } from "../schedule/schedule.service";

const router = Router();

const medicineSchema = z.object({
  medicineName: z.string().min(2),
  dosage: z.string().min(1),
  frequency: z.string().min(1),
  duration: z.string().min(1),
  instruction: z.string().min(1),
  quantityNeeded: z.number().int().positive(),
  activeSubstance: z.string().min(1)
});

const createPrescriptionSchema = z.object({
  appointmentId: z.string().uuid(),
  diagnosis: z.string().min(2),
  rawText: z.string().min(3),
  doctorComment: z.string().optional(),
  medicines: z.array(medicineSchema).optional()
});

const prescriptionInclude = {
  appointment: {
    include: {
      clinic: true,
      patientProfile: {
        include: {
          user: { select: { id: true, fullName: true, email: true, phone: true } }
        }
      },
      doctor: { select: { id: true, fullName: true, email: true, phone: true } }
    }
  },
  patientProfile: {
    include: {
      user: { select: { id: true, fullName: true, email: true, phone: true } }
    }
  },
  doctor: { select: { id: true, fullName: true, email: true, phone: true } },
  medicines: {
    include: {
      matches: {
        include: { product: true },
        orderBy: [{ isAlternative: "asc" }, { confidenceScore: "desc" }]
      },
      schedules: {
        orderBy: { takeTime: "asc" }
      }
    }
  }
} satisfies Prisma.PrescriptionInclude;

async function assertPrescriptionAccess(prescriptionId: string, auth: ReturnType<typeof getAuth>) {
  const prescription = await prisma.prescription.findUnique({
    where: { id: prescriptionId },
    include: prescriptionInclude
  });

  if (!prescription) {
    throw new HttpError(404, "Prescription not found");
  }

  const canRead =
    auth.role === UserRole.ADMIN ||
    prescription.patientProfile.userId === auth.userId ||
    prescription.doctorId === auth.userId;

  if (!canRead) {
    throw new HttpError(403, "No access to this prescription");
  }

  return prescription;
}

router.post(
  "/",
  authenticate,
  requireRole(UserRole.DOCTOR, UserRole.ADMIN),
  validateBody(createPrescriptionSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const body = req.body as z.infer<typeof createPrescriptionSchema>;
    const appointment = await prisma.appointment.findUnique({
      where: { id: body.appointmentId },
      include: { prescription: { select: { id: true } } }
    });

    if (!appointment) {
      throw new HttpError(404, "Appointment not found");
    }

    if (appointment.prescription) {
      throw new HttpError(409, "Для этого приёма уже существует назначение");
    }

    if (auth.role === UserRole.DOCTOR && appointment.doctorId !== auth.userId) {
      throw new HttpError(403, "Doctor can create prescriptions only for own appointments");
    }

    const prescription = await prisma.prescription.create({
      data: {
        appointmentId: appointment.id,
        patientProfileId: appointment.patientProfileId,
        doctorId: appointment.doctorId,
        diagnosis: body.diagnosis,
        rawText: body.rawText,
        doctorComment: body.doctorComment,
        aiDisclaimer: AI_DISCLAIMER,
        medicines: body.medicines?.length
          ? {
              create: body.medicines.map((medicine) => ({
                ...medicine,
                activeSubstance: medicine.activeSubstance.toLowerCase()
              }))
            }
          : undefined
      },
      include: prescriptionInclude
    });

    await prisma.appointment.update({
      where: { id: appointment.id },
      data: { status: "COMPLETED" }
    });

    for (const medicine of prescription.medicines) {
      await createMedicineMatches(medicine);
      await createScheduleForMedicine(prescription.patientProfileId, medicine);
    }

    const createdPrescription = await prisma.prescription.findUnique({
      where: { id: prescription.id },
      include: prescriptionInclude
    });

    res.status(201).json(createdPrescription);
  })
);

router.get(
  "/my",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const { patientProfileId } = req.query;

    const prescriptions = await prisma.prescription.findMany({
      where: {
        patientProfile: {
          userId: auth.userId,
          ...(patientProfileId ? { id: patientProfileId as string } : {})
        }
      },
      include: prescriptionInclude,
      orderBy: { createdAt: "desc" }
    });

    res.json(prescriptions);
  })
);

router.get(
  "/doctor",
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

router.get(
  "/:id",
  authenticate,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const prescription = await assertPrescriptionAccess(req.params.id, auth);
    res.json(prescription);
  })
);

router.post(
  "/:id/analyze-ai",
  authenticate,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const prescription = await assertPrescriptionAccess(req.params.id, auth);
    const parsed = await parsePrescription(prescription.rawText);

    await prisma.prescription.update({
      where: { id: prescription.id },
      data: {
        aiSummary: parsed.summary,
        aiDisclaimer: parsed.disclaimer || AI_DISCLAIMER,
        status: "ACTIVE"
      }
    });

    await prisma.prescriptionMedicine.deleteMany({
      where: { prescriptionId: prescription.id }
    });

    await prisma.prescriptionMedicine.createMany({
      data: parsed.medicines.map((medicine) => ({
        prescriptionId: prescription.id,
        medicineName: medicine.medicineName,
        dosage: medicine.dosage,
        frequency: medicine.frequency,
        duration: medicine.duration,
        instruction: medicine.instruction,
        quantityNeeded: medicine.quantityNeeded,
        activeSubstance: medicine.activeSubstance.toLowerCase()
      }))
    });

    const medicines = await prisma.prescriptionMedicine.findMany({
      where: { prescriptionId: prescription.id }
    });

    for (const medicine of medicines) {
      await createMedicineMatches(medicine);
      await createScheduleForMedicine(prescription.patientProfileId, medicine);
    }

    const analyzedPrescription = await prisma.prescription.findUnique({
      where: { id: prescription.id },
      include: prescriptionInclude
    });

    res.json(analyzedPrescription);
  })
);

router.get(
  "/:id/market-products",
  authenticate,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const prescription = await assertPrescriptionAccess(req.params.id, auth);

    for (const medicine of prescription.medicines) {
      if (!medicine.matches.length) {
        await createMedicineMatches(medicine);
      }
    }

    const medicines = await prisma.prescriptionMedicine.findMany({
      where: { prescriptionId: prescription.id },
      include: {
        matches: {
          include: { product: true },
          orderBy: [{ isAlternative: "asc" }, { confidenceScore: "desc" }]
        }
      }
    });

    res.json(
      medicines.map((medicine) => ({
        prescriptionMedicine: medicine,
        products: medicine.matches.map((match) => ({
          matchId: match.id,
          matchType: match.matchType,
          confidenceScore: match.confidenceScore,
          isAlternative: match.isAlternative,
          product: match.product
        }))
      }))
    );
  })
);

router.get(
  "/:id/schedule",
  authenticate,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const prescription = await assertPrescriptionAccess(req.params.id, auth);

    const medicineIds = prescription.medicines.map((medicine) => medicine.id);
    let schedule = await prisma.medicationSchedule.findMany({
      where: {
        patientProfileId: prescription.patientProfileId,
        prescriptionMedicineId: { in: medicineIds }
      },
      include: { prescriptionMedicine: true },
      orderBy: { takeTime: "asc" }
    });

    if (!schedule.length) {
      for (const medicine of prescription.medicines) {
        await createScheduleForMedicine(prescription.patientProfileId, medicine);
      }

      schedule = await prisma.medicationSchedule.findMany({
        where: {
          patientProfileId: prescription.patientProfileId,
          prescriptionMedicineId: { in: medicineIds }
        },
        include: { prescriptionMedicine: true },
        orderBy: { takeTime: "asc" }
      });
    }

    res.json(schedule);
  })
);

export default router;
