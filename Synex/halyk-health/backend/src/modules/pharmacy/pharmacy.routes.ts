import { Router } from "express";
import { UserRole, PharmacyStockMovementReason, PharmacyOrderStatus } from "@prisma/client";
import { z } from "zod";
import { authenticate, getAuth, requireRole } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { HttpError } from "../../common/http-error";
import { prisma } from "../../common/prisma";
import { validateBody } from "../../common/validation";

const router = Router();

// ─── Middleware: resolve pharmacy for current user ────────────────────────────

async function getPharmacyForUser(userId: string) {
  const staffEntry = await prisma.pharmacyStaff.findFirst({
    where: { userId, isActive: true },
    include: { pharmacy: true }
  });
  if (!staffEntry) {
    throw new HttpError(403, "User is not associated with any pharmacy");
  }
  return staffEntry.pharmacy;
}

const pharmacyMiddleware = requireRole(
  UserRole.PHARMACY_ADMIN,
  UserRole.PHARMACY_STAFF,
  UserRole.ADMIN
);

// ─── Profile ──────────────────────────────────────────────────────────────────

router.get(
  "/me",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    if (auth.role === UserRole.ADMIN) {
      const pharmacies = await prisma.pharmacy.findMany({
        include: { _count: { select: { products: true, orders: true, staff: true } } }
      });
      res.json(pharmacies);
      return;
    }
    const pharmacy = await getPharmacyForUser(auth.userId);
    res.json(pharmacy);
  })
);

const updatePharmacySchema = z.object({
  name: z.string().min(2).optional(),
  address: z.string().optional(),
  city: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  workingHours: z.string().optional(),
  deliveryEnabled: z.boolean().optional(),
  pickupEnabled: z.boolean().optional()
});

router.patch(
  "/me",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  validateBody(updatePharmacySchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const updated = await prisma.pharmacy.update({
      where: { id: pharmacy.id },
      data: req.body
    });
    res.json(updated);
  })
);

// ─── Products ─────────────────────────────────────────────────────────────────

const productSchema = z.object({
  name: z.string().min(2),
  activeSubstance: z.string().min(1),
  dosage: z.string().min(1),
  form: z.enum(["TABLET", "SYRUP", "SPRAY", "CAPSULE", "DROPS", "OINTMENT", "INJECTION", "OTHER"]).default("OTHER"),
  category: z.string().optional(),
  manufacturer: z.string().optional(),
  price: z.number().positive(),
  stock: z.number().int().min(0).default(0),
  minStock: z.number().int().min(0).default(5),
  imageUrl: z.string().url().optional().nullable(),
  isAvailable: z.boolean().default(true),
  requiresPrescription: z.boolean().default(false),
  description: z.string().optional()
});

router.get(
  "/products",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const { search, category, stockStatus } = req.query;

    const where: any = { pharmacyId: pharmacy.id };

    if (search) {
      where.OR = [
        { name: { contains: String(search), mode: "insensitive" } },
        { activeSubstance: { contains: String(search), mode: "insensitive" } }
      ];
    }
    if (category) {
      where.category = { equals: String(category), mode: "insensitive" };
    }
    if (stockStatus === "in_stock") {
      where.stock = { gt: 5 };
    } else if (stockStatus === "low") {
      where.AND = [{ stock: { lte: prisma.pharmacyProduct.fields.minStock } }];
      where.stock = { gt: 0 };
    } else if (stockStatus === "out") {
      where.stock = { lte: 0 };
    }

    const products = await prisma.pharmacyProduct.findMany({
      where,
      orderBy: { name: "asc" }
    });
    res.json(products);
  })
);

router.post(
  "/products",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  validateBody(productSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const product = await prisma.pharmacyProduct.create({
      data: { ...req.body, pharmacyId: pharmacy.id }
    });
    res.status(201).json(product);
  })
);

router.get(
  "/products/:id",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const product = await prisma.pharmacyProduct.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!product) throw new HttpError(404, "Product not found");
    res.json(product);
  })
);

router.patch(
  "/products/:id",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  validateBody(productSchema.partial()),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const existing = await prisma.pharmacyProduct.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!existing) throw new HttpError(404, "Product not found");
    const updated = await prisma.pharmacyProduct.update({
      where: { id: req.params.id },
      data: req.body
    });
    res.json(updated);
  })
);

router.delete(
  "/products/:id",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const existing = await prisma.pharmacyProduct.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!existing) throw new HttpError(404, "Product not found");
    await prisma.pharmacyProduct.update({
      where: { id: req.params.id },
      data: { isAvailable: false }
    });
    res.json({ success: true });
  })
);

// ─── Stock ────────────────────────────────────────────────────────────────────

const stockUpdateSchema = z.object({
  quantity: z.number().int(),
  reason: z.nativeEnum(PharmacyStockMovementReason),
  comment: z.string().optional()
});

router.patch(
  "/products/:id/stock",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.PHARMACY_STAFF, UserRole.ADMIN),
  validateBody(stockUpdateSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const product = await prisma.pharmacyProduct.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!product) throw new HttpError(404, "Product not found");

    const newStock = product.stock + req.body.quantity;
    if (newStock < 0) throw new HttpError(400, "Stock cannot go below zero");

    const [updatedProduct] = await prisma.$transaction([
      prisma.pharmacyProduct.update({
        where: { id: req.params.id },
        data: {
          stock: newStock,
          isAvailable: newStock > 0
        }
      }),
      prisma.pharmacyStockMovement.create({
        data: {
          productId: req.params.id,
          quantity: req.body.quantity,
          reason: req.body.reason,
          comment: req.body.comment,
          createdBy: auth.userId
        }
      })
    ]);

    res.json(updatedProduct);
  })
);

router.get(
  "/products/:id/stock-movements",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const product = await prisma.pharmacyProduct.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!product) throw new HttpError(404, "Product not found");

    const movements = await prisma.pharmacyStockMovement.findMany({
      where: { productId: req.params.id },
      orderBy: { createdAt: "desc" },
      take: 50
    });
    res.json(movements);
  })
);

// ─── Orders ───────────────────────────────────────────────────────────────────

router.get(
  "/orders",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const { status } = req.query;

    const orders = await prisma.pharmacyOrder.findMany({
      where: {
        pharmacyId: pharmacy.id,
        ...(status ? { status: status as PharmacyOrderStatus } : {})
      },
      include: {
        items: { include: { product: { select: { name: true, imageUrl: true } } } }
      },
      orderBy: { createdAt: "desc" }
    });
    res.json(orders);
  })
);

router.get(
  "/orders/:id",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const order = await prisma.pharmacyOrder.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id },
      include: {
        items: { include: { product: true } }
      }
    });
    if (!order) throw new HttpError(404, "Order not found");
    res.json(order);
  })
);

const orderStatusSchema = z.object({
  status: z.nativeEnum(PharmacyOrderStatus)
});

router.patch(
  "/orders/:id/status",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.PHARMACY_STAFF, UserRole.ADMIN),
  validateBody(orderStatusSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const order = await prisma.pharmacyOrder.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!order) throw new HttpError(404, "Order not found");
    const updated = await prisma.pharmacyOrder.update({
      where: { id: req.params.id },
      data: { status: req.body.status },
      include: { items: { include: { product: true } } }
    });
    res.json(updated);
  })
);

const itemAvailabilitySchema = z.object({
  itemId: z.string().uuid(),
  isAvailable: z.boolean()
});

router.patch(
  "/orders/:id/item-availability",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.PHARMACY_STAFF, UserRole.ADMIN),
  validateBody(itemAvailabilitySchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const order = await prisma.pharmacyOrder.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!order) throw new HttpError(404, "Order not found");
    const updatedItem = await prisma.pharmacyOrderItem.update({
      where: { id: req.body.itemId },
      data: { isAvailable: req.body.isAvailable }
    });
    res.json(updatedItem);
  })
);

router.get(
  "/orders/:id/alternatives",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const order = await prisma.pharmacyOrder.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id },
      include: { items: { include: { product: true } } }
    });
    if (!order) throw new HttpError(404, "Order not found");

    const unavailableItems = order.items.filter((item) => !item.isAvailable);
    const alternatives: Record<string, any[]> = {};

    for (const item of unavailableItems) {
      const alts = await prisma.pharmacyProduct.findMany({
        where: {
          pharmacyId: pharmacy.id,
          activeSubstance: { equals: item.product.activeSubstance, mode: "insensitive" },
          id: { not: item.productId },
          stock: { gt: 0 }
        }
      });
      alternatives[item.id] = alts;
    }

    res.json(alternatives);
  })
);

// ─── Staff ────────────────────────────────────────────────────────────────────

router.get(
  "/staff",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const staff = await prisma.pharmacyStaff.findMany({
      where: { pharmacyId: pharmacy.id },
      include: { user: { select: { id: true, fullName: true, email: true, phone: true, role: true } } },
      orderBy: { createdAt: "asc" }
    });
    res.json(staff);
  })
);

const addStaffSchema = z.object({
  email: z.string().email(),
  fullName: z.string().min(2),
  phone: z.string().min(6),
  password: z.string().min(6),
  role: z.enum(["PHARMACY_ADMIN", "PHARMACY_STAFF"]).default("PHARMACY_STAFF")
});

router.post(
  "/staff",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  validateBody(addStaffSchema),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);

    const existing = await prisma.user.findFirst({
      where: { OR: [{ email: req.body.email }, { phone: req.body.phone }] }
    });

    let user = existing;
    if (!user) {
      const bcrypt = await import("bcryptjs");
      const passwordHash = await bcrypt.hash(req.body.password, 10);
      user = await prisma.user.create({
        data: {
          fullName: req.body.fullName,
          email: req.body.email,
          phone: req.body.phone,
          passwordHash,
          role: req.body.role as UserRole
        }
      });
    } else {
      await prisma.user.update({
        where: { id: user.id },
        data: { role: req.body.role as UserRole }
      });
    }

    const staffEntry = await prisma.pharmacyStaff.upsert({
      where: { userId_pharmacyId: { userId: user.id, pharmacyId: pharmacy.id } },
      create: { userId: user.id, pharmacyId: pharmacy.id, isActive: true },
      update: { isActive: true },
      include: { user: { select: { id: true, fullName: true, email: true, phone: true, role: true } } }
    });

    res.status(201).json(staffEntry);
  })
);

router.patch(
  "/staff/:id",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  validateBody(z.object({ isActive: z.boolean().optional(), role: z.enum(["PHARMACY_ADMIN", "PHARMACY_STAFF"]).optional() })),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const staffEntry = await prisma.pharmacyStaff.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!staffEntry) throw new HttpError(404, "Staff member not found");

    const updated = await prisma.pharmacyStaff.update({
      where: { id: req.params.id },
      data: { isActive: req.body.isActive },
      include: { user: { select: { id: true, fullName: true, email: true, phone: true, role: true } } }
    });

    if (req.body.role) {
      await prisma.user.update({
        where: { id: staffEntry.userId },
        data: { role: req.body.role as UserRole }
      });
    }

    res.json(updated);
  })
);

router.delete(
  "/staff/:id",
  authenticate,
  requireRole(UserRole.PHARMACY_ADMIN, UserRole.ADMIN),
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);
    const staffEntry = await prisma.pharmacyStaff.findFirst({
      where: { id: req.params.id, pharmacyId: pharmacy.id }
    });
    if (!staffEntry) throw new HttpError(404, "Staff member not found");
    await prisma.pharmacyStaff.update({
      where: { id: req.params.id },
      data: { isActive: false }
    });
    res.json({ success: true });
  })
);

// ─── Dashboard summary ────────────────────────────────────────────────────────

router.get(
  "/dashboard",
  authenticate,
  pharmacyMiddleware,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const pharmacy = await getPharmacyForUser(auth.userId);

    const [newOrders, processingOrders, lowStockProducts, totalProducts] = await Promise.all([
      prisma.pharmacyOrder.count({ where: { pharmacyId: pharmacy.id, status: "NEW" } }),
      prisma.pharmacyOrder.count({
        where: { pharmacyId: pharmacy.id, status: { in: ["CONFIRMED", "PREPARING", "DELIVERING", "READY_FOR_PICKUP"] } }
      }),
      prisma.pharmacyProduct.count({
        where: { pharmacyId: pharmacy.id, stock: { lte: 5 }, isAvailable: true }
      }),
      prisma.pharmacyProduct.count({ where: { pharmacyId: pharmacy.id } })
    ]);

    const recentOrders = await prisma.pharmacyOrder.findMany({
      where: { pharmacyId: pharmacy.id },
      include: { items: true },
      orderBy: { createdAt: "desc" },
      take: 5
    });

    res.json({
      pharmacy,
      stats: { newOrders, processingOrders, lowStockProducts, totalProducts },
      recentOrders
    });
  })
);

export default router;
