import { randomUUID } from "node:crypto";
import bcrypt from "bcryptjs";
import { eq } from "drizzle-orm";
import jwt, { type SignOptions } from "jsonwebtoken";
import { getDb } from "../db/client.js";
import { users, type User } from "../db/schema.js";

const passwordSaltRounds = 12;
const jwtExpiresIn: SignOptions["expiresIn"] = "7d";

export class AuthError extends Error {
  constructor(
    message: string,
    public readonly statusCode: 400 | 401 | 409 | 500,
  ) {
    super(message);
    this.name = "AuthError";
  }
}

export type AuthCredentials = {
  email: string;
  password: string;
};

export type AuthResult = {
  token: string;
  user: {
    id: string;
    email: string;
    createdAt: string;
  };
};

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function readJwtSecret(): string {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new AuthError("Missing required environment variable: JWT_SECRET", 500);
  }

  return secret;
}

function toAuthResult(user: User): AuthResult {
  const token = jwt.sign(
    { email: user.email },
    readJwtSecret(),
    {
      subject: user.id,
      expiresIn: jwtExpiresIn,
    },
  );

  return {
    token,
    user: {
      id: user.id,
      email: user.email,
      createdAt: user.createdAt,
    },
  };
}

export async function registerUser(credentials: AuthCredentials): Promise<AuthResult> {
  const db = getDb();
  const email = normalizeEmail(credentials.email);
  const existingUser = await db.select().from(users).where(eq(users.email, email)).limit(1);

  if (existingUser.length > 0) {
    throw new AuthError("Email is already registered", 409);
  }

  const passwordHash = await bcrypt.hash(credentials.password, passwordSaltRounds);
  const userId = randomUUID();

  await db.insert(users).values({
    id: userId,
    email,
    passwordHash,
  });

  const [createdUser] = await db.select().from(users).where(eq(users.id, userId)).limit(1);

  if (!createdUser) {
    throw new AuthError("Failed to create user", 500);
  }

  return toAuthResult(createdUser);
}

export async function loginUser(credentials: AuthCredentials): Promise<AuthResult> {
  const db = getDb();
  const email = normalizeEmail(credentials.email);
  const [user] = await db.select().from(users).where(eq(users.email, email)).limit(1);

  if (!user) {
    throw new AuthError("Invalid email or password", 401);
  }

  const passwordMatches = await bcrypt.compare(credentials.password, user.passwordHash);

  if (!passwordMatches) {
    throw new AuthError("Invalid email or password", 401);
  }

  return toAuthResult(user);
}
