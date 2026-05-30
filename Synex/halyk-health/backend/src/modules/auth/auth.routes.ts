import { Router } from "express";
import bcrypt from "bcryptjs";
import { UserRole } from "@prisma/client";
import { z } from "zod";
import { prisma } from "../../common/prisma";
import { HttpError } from "../../common/http-error";
import { authenticate, getAuth, signAuthToken } from "../../common/auth";
import { asyncHandler } from "../../common/async-handler";
import { validateBody } from "../../common/validation";

const router = Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

const registerSchema = z.object({
  fullName: z.string().min(2),
  phone: z.string().min(6),
  email: z.string().email(),
  password: z.string().min(6),
  role: z.nativeEnum(UserRole).default(UserRole.PATIENT),
  birthDate: z.string().optional(),
  address: z.string().optional()
});

function sanitizeUser<T extends { passwordHash?: string }>(user: T) {
  const { passwordHash: _passwordHash, ...safeUser } = user;
  return safeUser;
}

router.post(
  "/login",
  validateBody(loginSchema),
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findUnique({
      where: { email: req.body.email },
      include: { doctorProfile: { include: { clinic: true } } }
    });

    if (!user) {
      throw new HttpError(401, "Invalid email or password");
    }

    const passwordMatches = await bcrypt.compare(req.body.password, user.passwordHash);
    if (!passwordMatches) {
      throw new HttpError(401, "Invalid email or password");
    }

    res.json({
      token: signAuthToken(user),
      user: sanitizeUser(user)
    });
  })
);

router.post(
  "/register",
  validateBody(registerSchema),
  asyncHandler(async (req, res) => {
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [{ email: req.body.email }, { phone: req.body.phone }]
      }
    });

    if (existingUser) {
      throw new HttpError(409, "User with this email or phone already exists");
    }

    const passwordHash = await bcrypt.hash(req.body.password, 10);
    const user = await prisma.user.create({
      data: {
        fullName: req.body.fullName,
        phone: req.body.phone,
        email: req.body.email,
        passwordHash,
        role: req.body.role,
        birthDate: req.body.birthDate ? new Date(req.body.birthDate) : undefined,
        address: req.body.address
      }
    });

    res.status(201).json({
      token: signAuthToken(user),
      user: sanitizeUser(user)
    });
  })
);

router.get(
  "/me",
  authenticate,
  asyncHandler(async (req, res) => {
    const auth = getAuth(req);
    const user = await prisma.user.findUnique({
      where: { id: auth.userId },
      include: { doctorProfile: { include: { clinic: true } } }
    });

    if (!user) {
      throw new HttpError(404, "User not found");
    }

    res.json(sanitizeUser(user));
  })
);

export default router;

