import { Router } from "express";
import { RelationType, InsuranceStatus, UserRole } from "@prisma/client";
import { z } from "zod";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { HttpError } from "../../common/http-error";
import { prisma } from "../../common/prisma";
import { validateBody } from "../../common/validation";

const router = Router();

const patientProfileSchema = z.object({
  fullName: z.string().min(2),
  iin: z.string().length(12).optional(),
  relationType: z.nativeEnum(RelationType),
  insuranceStatus: z.nativeEnum(InsuranceStatus).default(InsuranceStatus.ACTIVE),
  clinicId: z.string().uuid().optional(),
  primaryDoctorId: z.string().uuid().optional()
});

const updatePatientProfileSchema = patientProfileSchema.partial();

router.get(
  "/my",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const profiles = await prisma.patientProfile.findMany({
      where: { userId: auth.userId },
      include: {
        clinic: true,
        primaryDoctor: {
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                email: true,
                phone: true,
                role: true
              }
            }
          }
        }
      },
      orderBy: { relationType: "asc" }
    });
    res.json(profiles);
  })
);

router.post(
  "/",
  authenticate,
  requireRole(UserRole.PATIENT),
  validateBody(patientProfileSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const profile = await prisma.patientProfile.create({
      data: {
        ...req.body,
        userId: auth.userId
      },
      include: {
        clinic: true,
        primaryDoctor: true
      }
    });
    res.status(201).json(profile);
  })
);

router.get(
  "/:id/appointment-context",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const profile = await prisma.patientProfile.findUnique({
      where: { id: req.params.id },
      include: {
        clinic: true,
        primaryDoctor: {
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                email: true,
                phone: true,
                role: true
              }
            }
          }
        }
      }
    });

    if (!profile || profile.userId !== auth.userId) {
      throw new HttpError(404, "Patient profile not found");
    }

    res.json({
      insuranceStatus: profile.insuranceStatus,
      clinic: profile.clinic,
      primaryDoctor: profile.primaryDoctor
    });
  })
);

router.patch(
  "/:id",
  authenticate,
  requireRole(UserRole.PATIENT),
  validateBody(updatePatientProfileSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const profile = await prisma.patientProfile.findUnique({
      where: { id: req.params.id }
    });

    if (!profile || profile.userId !== auth.userId) {
      throw new HttpError(404, "Patient profile not found");
    }

    const updated = await prisma.patientProfile.update({
      where: { id: req.params.id },
      data: req.body,
      include: {
        clinic: true,
        primaryDoctor: true
      }
    });

    res.json(updated);
  })
);

router.delete(
  "/:id",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const profile = await prisma.patientProfile.findUnique({
      where: { id: req.params.id }
    });

    if (!profile || profile.userId !== auth.userId) {
      throw new HttpError(404, "Patient profile not found");
    }

    if (profile.relationType === RelationType.SELF) {
      throw new HttpError(400, "Cannot delete SELF profile");
    }

    await prisma.patientProfile.delete({
      where: { id: req.params.id }
    });

    res.status(204).end();
  })
);

export default router;
