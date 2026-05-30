import { Router } from "express";
import { z } from "zod";
import { authenticate } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { validateBody } from "../../common/validation";
import { parsePrescription } from "./ai.service";

const router = Router();

const parsePrescriptionSchema = z.object({
  rawText: z.string().min(3)
});

router.post(
  "/parse-prescription",
  authenticate,
  validateBody(parsePrescriptionSchema),
  asyncHandler(async (req, res) => {
    const parsed = await parsePrescription(req.body.rawText);
    res.json(parsed);
  })
);

export default router;

