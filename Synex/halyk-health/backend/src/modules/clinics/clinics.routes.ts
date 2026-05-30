import { Router } from "express";
import { prisma } from "../../common/prisma";
import { asyncHandler } from "../../common/async-handler";
import { HttpError } from "../../common/http-error";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const clinics = await prisma.clinic.findMany({
      orderBy: { name: "asc" }
    });

    res.json(clinics);
  })
);

router.get(
  "/:id",
  asyncHandler(async (req, res) => {
    const clinic = await prisma.clinic.findUnique({
      where: { id: req.params.id },
      include: {
        doctors: {
          include: {
            user: {
              select: { id: true, fullName: true, email: true, phone: true, role: true }
            }
          }
        }
      }
    });

    if (!clinic) {
      throw new HttpError(404, "Clinic not found");
    }

    res.json(clinic);
  })
);

router.get(
  "/:id/doctors",
  asyncHandler(async (req, res) => {
    const doctors = await prisma.doctorProfile.findMany({
      where: { clinicId: req.params.id },
      include: {
        user: {
          select: { id: true, fullName: true, email: true, phone: true, role: true }
        },
        clinic: true
      },
      orderBy: { specialization: "asc" }
    });

    res.json(doctors);
  })
);

export default router;

