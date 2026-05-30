import type { NextFunction, Request, RequestHandler, Response } from "express";
import jwt from "jsonwebtoken";
import type { UserRole } from "@prisma/client";
import { HttpError } from "./http-error";

export type AuthUser = {
  userId: string;
  email: string;
  role: UserRole;
};

declare global {
  namespace Express {
    interface Request {
      auth?: AuthUser;
    }
  }
}

const jwtSecret = () => process.env.JWT_SECRET || "local-dev-secret";

export function signAuthToken(user: { id: string; email: string; role: UserRole }) {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      role: user.role
    },
    jwtSecret(),
    { expiresIn: "7d" }
  );
}

export const authenticate: RequestHandler = (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;

  if (!header?.startsWith("Bearer ")) {
    next(new HttpError(401, "Authorization token is required"));
    return;
  }

  try {
    const payload = jwt.verify(header.slice("Bearer ".length), jwtSecret()) as jwt.JwtPayload;

    if (!payload.sub || !payload.email || !payload.role) {
      next(new HttpError(401, "Invalid token payload"));
      return;
    }

    req.auth = {
      userId: String(payload.sub),
      email: String(payload.email),
      role: payload.role as UserRole
    };
    next();
  } catch {
    next(new HttpError(401, "Invalid or expired token"));
  }
};

export function requireRole(...roles: UserRole[]): RequestHandler {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.auth) {
      next(new HttpError(401, "Authorization token is required"));
      return;
    }

    if (!roles.includes(req.auth.role)) {
      next(new HttpError(403, "Insufficient role permissions"));
      return;
    }

    next();
  };
}

export function getAuth(req: Request): AuthUser {
  if (!req.auth) {
    throw new HttpError(401, "Authorization token is required");
  }

  return req.auth;
}

