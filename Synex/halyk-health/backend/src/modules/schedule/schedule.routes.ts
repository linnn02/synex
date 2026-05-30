import { Router } from "express";
import { ScheduleStatus, UserRole } from "@prisma/client";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { HttpError } from "../../common/http-error";
import { prisma } from "../../common/prisma";

const router = Router();

router.get(
  "/my",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const { patientProfileId } = req.query;

    const schedule = await prisma.medicationSchedule.findMany({
      where: {
        patientProfile: {
          userId: auth.userId,
          ...(patientProfileId ? { id: patientProfileId as string } : {})
        }
      },
      include: {
        prescriptionMedicine: {
          include: { prescription: true }
        }
      },
      orderBy: { takeTime: "asc" }
    });

    res.json(schedule);
  })
);

router.patch(
  "/:id/taken",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const item = await prisma.medicationSchedule.findUnique({
      where: { id: req.params.id },
      include: { patientProfile: true }
    });

    if (!item || item.patientProfile.userId !== auth.userId) {
      throw new HttpError(404, "Schedule item not found");
    }

    const updatedItem = await prisma.medicationSchedule.update({
      where: { id: req.params.id },
      data: { status: ScheduleStatus.TAKEN, takenAt: new Date() },
      include: { prescriptionMedicine: true }
    });

    res.json(updatedItem);
  })
);

router.patch(
  "/:id/missed",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const item = await prisma.medicationSchedule.findUnique({
      where: { id: req.params.id },
      include: { patientProfile: true }
    });

    if (!item || item.patientProfile.userId !== auth.userId) {
      throw new HttpError(404, "Schedule item not found");
    }

    const updatedItem = await prisma.medicationSchedule.update({
      where: { id: req.params.id },
      data: { status: ScheduleStatus.MISSED, takenAt: null },
      include: { prescriptionMedicine: true }
    });

    res.json(updatedItem);
  })
);

export default router;
