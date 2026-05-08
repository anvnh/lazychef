import type { Context } from "hono";
import { Hono } from "hono";
import { z } from "zod";
import {
  AuthError,
  loginUser,
  registerUser,
  type AuthCredentials,
} from "../auth/auth.service.js";

const credentialsSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(8).max(128),
});

export const authRoutes = new Hono();

authRoutes.post("/register", async (context) => {
  const credentials = await parseCredentials(context.req.json());

  if (!credentials.ok) {
    return context.json(
      { error: "Invalid request body", fields: credentials.fields },
      400,
    );
  }

  try {
    const result = await registerUser(credentials.data);

    return context.json(result, 201);
  } catch (error) {
    return handleAuthError(context, error);
  }
});

authRoutes.post("/login", async (context) => {
  const credentials = await parseCredentials(context.req.json());

  if (!credentials.ok) {
    return context.json(
      { error: "Invalid request body", fields: credentials.fields },
      400,
    );
  }

  try {
    const result = await loginUser(credentials.data);

    return context.json(result);
  } catch (error) {
    return handleAuthError(context, error);
  }
});

async function parseCredentials(
  bodyPromise: Promise<unknown>,
): Promise<
  | { ok: true; data: AuthCredentials }
  | { ok: false; fields: Record<string, string[] | undefined> }
> {
  const body = await bodyPromise.catch(() => null);
  const parsed = credentialsSchema.safeParse(body);

  if (!parsed.success) {
    return {
      ok: false,
      fields: parsed.error.flatten().fieldErrors,
    };
  }

  return {
    ok: true,
    data: parsed.data,
  };
}

function handleAuthError(context: Context, error: unknown) {
  if (error instanceof AuthError) {
    return context.json({ error: error.message }, error.statusCode);
  }

  return context.json({ error: "Unexpected authentication error" }, 500);
}
