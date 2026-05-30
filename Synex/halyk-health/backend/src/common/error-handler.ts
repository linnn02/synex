import type { ErrorRequestHandler, RequestHandler } from "express";
import { HttpError } from "./http-error";

export const notFoundHandler: RequestHandler = (req, _res, next) => {
  next(new HttpError(404, `Route ${req.method} ${req.path} not found`));
};

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  const statusCode = error instanceof HttpError ? error.statusCode : 500;

  res.status(statusCode).json({
    error: {
      message: error.message || "Internal server error",
      details: error instanceof HttpError ? error.details : undefined
    }
  });
};

