import { createMiddleware } from "hono/factory";
import jwt from "jsonwebtoken";

export type AuthenticatedUser = {
  id: string;
  email: string;
};

declare module "hono" {
  interface ContextVariableMap {
    user: AuthenticatedUser;
  }
}

function readJwtSecret(): string {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new Error("Missing required environment variable: JWT_SECRET");
  }

  return secret;
}

export const authMiddleware = createMiddleware(async (context, next) => {
  const authorization = context.req.header("Authorization");
  const token = authorization?.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length)
    : null;

  if (!token) {
    return context.json({ error: "Missing bearer token" }, 401);
  }

  try {
    const payload = jwt.verify(token, readJwtSecret());

    if (typeof payload === "string" || !payload.sub) {
      return context.json({ error: "Invalid bearer token" }, 401);
    }

    context.set("user", {
      id: String(payload.sub),
      email: typeof payload.email === "string" ? payload.email : "",
    });

    await next();
  } catch {
    return context.json({ error: "Invalid bearer token" }, 401);
  }
});
