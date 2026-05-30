import { Router } from "express";
import { UserRole } from "@prisma/client";
import { prisma } from "../../common/prisma";
import { authenticate } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";

const router = Router();

router.get(
  "/doctors",
  authenticate,
  asyncHandler(async (_req, res) => {
    const doctors = await prisma.user.findMany({
      where: { role: UserRole.DOCTOR },
      select: {
        id: true,
        fullName: true,
        email: true,
        phone: true,
        role: true,
        doctorProfile: {
          include: { clinic: true }
        }
      },
      orderBy: { fullName: "asc" }
    });

    res.json(doctors);
  })
);

export default router;

