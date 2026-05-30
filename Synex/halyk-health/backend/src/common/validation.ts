import type { NextFunction, Request, RequestHandler, Response } from "express";
import type { ZodTypeAny } from "zod";
import { HttpError } from "./http-error";

export function validateBody(schema: ZodTypeAny): RequestHandler {
  return (req: Request, _res: Response, next: NextFunction) => {
    const parsed = schema.safeParse(req.body);

    if (!parsed.success) {
      next(new HttpError(400, "Validation failed", parsed.error.flatten()));
      return;
    }

    req.body = parsed.data;
    next();
  };
}

