import { Router } from "express";
import { UserRole, RelationType } from "@prisma/client";
import { z } from "zod";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { HttpError } from "../../common/http-error";
import { prisma } from "../../common/prisma";
import { validateBody } from "../../common/validation";
import { findAlternatives, findProductsByMedicineName } from "./market.service";

const router = Router();

const addCartItemSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().positive().default(1),
  patientProfileId: z.string().uuid().optional()
});

const updateCartItemSchema = z.object({
  quantity: z.number().int().min(0)
});

router.get(
  "/products",
  asyncHandler(async (_req, res) => {
    const products = await prisma.marketProduct.findMany({
      orderBy: [{ stock: "desc" }, { title: "asc" }]
    });

    res.json(products);
  })
);

router.get(
  "/search",
  asyncHandler(async (req, res) => {
    const query = String(req.query.query || "").trim();

    if (!query) {
      res.json([]);
      return;
    }

    const products = await findProductsByMedicineName(query);
    res.json(products);
  })
);

router.get(
  "/alternatives",
  asyncHandler(async (req, res) => {
    const activeSubstance = String(req.query.activeSubstance || "").trim();

    if (!activeSubstance) {
      res.json([]);
      return;
    }

    const products = await findAlternatives(activeSubstance);
    res.json(products);
  })
);

router.post(
  "/cart",
  authenticate,
  requireRole(UserRole.PATIENT),
  validateBody(addCartItemSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const product = await prisma.marketProduct.findUnique({ where: { id: req.body.productId } });

    if (!product) {
      throw new HttpError(404, "Market product not found");
    }

    let patientProfileId = req.body.patientProfileId;

    if (!patientProfileId) {
      const selfProfile = await prisma.patientProfile.findFirst({
        where: { userId: auth.userId, relationType: RelationType.SELF }
      });
      if (!selfProfile) {
        throw new HttpError(404, "Self patient profile not found");
      }
      patientProfileId = selfProfile.id;
    }

    const cartItem = await prisma.cartItem.upsert({
      where: {
        patientProfileId_productId: {
          patientProfileId,
          productId: req.body.productId
        }
      },
      update: {
        quantity: { increment: req.body.quantity }
      },
      create: {
        patientProfileId,
        productId: req.body.productId,
        quantity: req.body.quantity
      },
      include: { product: true }
    });

    res.status(201).json(cartItem);
  })
);

router.get(
  "/cart",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const cart = await prisma.cartItem.findMany({
      where: {
        patientProfile: { userId: auth.userId }
      },
      include: { product: true },
      orderBy: { createdAt: "desc" }
    });

    res.json(cart);
  })
);

router.patch(
  "/cart/:id",
  authenticate,
  requireRole(UserRole.PATIENT),
  validateBody(updateCartItemSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const cartItem = await prisma.cartItem.findUnique({
      where: { id: req.params.id },
      include: { patientProfile: true }
    });

    if (!cartItem || cartItem.patientProfile.userId !== auth.userId) {
      throw new HttpError(404, "Cart item not found");
    }

    if (req.body.quantity === 0) {
      await prisma.cartItem.delete({ where: { id: req.params.id } });
      res.json({ deleted: true });
      return;
    }

    const updatedItem = await prisma.cartItem.update({
      where: { id: req.params.id },
      data: { quantity: req.body.quantity },
      include: { product: true }
    });

    res.json(updatedItem);
  })
);

router.delete(
  "/cart/:id",
  authenticate,
  requireRole(UserRole.PATIENT),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const cartItem = await prisma.cartItem.findUnique({
      where: { id: req.params.id },
      include: { patientProfile: true }
    });

    if (!cartItem || cartItem.patientProfile.userId !== auth.userId) {
      throw new HttpError(404, "Cart item not found");
    }

    await prisma.cartItem.delete({ where: { id: req.params.id } });
    res.json({ deleted: true });
  })
);

export default router;
