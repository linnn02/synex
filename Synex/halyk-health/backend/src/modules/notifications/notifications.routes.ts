import { Router } from "express";
import { authenticate } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";

const router = Router();

router.get(
  "/mock",
  authenticate,
  asyncHandler(async (_req, res) => {
    res.json({
      provider: "mock",
      status: "ready",
      message: "Push notifications module placeholder for future Halyk Super App integration."
    });
  })
);

export default router;

