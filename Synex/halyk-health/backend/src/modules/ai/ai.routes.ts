import { Router } from "express";
import { z } from "zod";
import { authenticate } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { validateBody } from "../../common/validation";
import {
  parsePrescription,
  validatePrescription,
  explainPrescription,
  generateDemandReport
} from "./ai.service";
import { prisma } from "../../common/prisma";

const router = Router();

router.post(
  "/parse-prescription",
  authenticate,
  validateBody(z.object({ rawText: z.string() })),
  asyncHandler(async (req, res) => {
    const parsed = await parsePrescription(req.body.rawText);
    res.json(parsed);
  })
);

router.post(
  "/validate-prescription",
  authenticate,
  validateBody(z.object({ rawText: z.string() })),
  asyncHandler(async (req, res) => {
    const result = await validatePrescription(req.body.rawText);
    res.json(result);
  })
);

router.post(
  "/explain-prescription",
  authenticate,
  validateBody(z.object({ prescriptionId: z.string() })),
  asyncHandler(async (req, res) => {
    const prescription = await prisma.prescription.findUnique({
      where: { id: req.body.prescriptionId },
      include: { medicines: true }
    });
    if (!prescription) throw new Error("Prescription not found");
    const explanation = await explainPrescription(prescription);
    res.json({ explanation });
  })
);

router.get(
  "/demand-report",
  authenticate,
  asyncHandler(async (req, res) => {
    const prescriptions = await prisma.prescriptionMedicine.findMany({
      take: 100,
      orderBy: { createdAt: "desc" }
    });
    const cartItems = await prisma.cartItem.findMany({
      take: 100,
      include: { product: true }
    });
    
    const data = {
      recentMedicines: prescriptions.map(m => m.medicineName),
      cartProducts: cartItems.map(c => c.product.title)
    };
    
    const report = await generateDemandReport(JSON.stringify(data));
    res.json(report);
  })
);

export default router;

