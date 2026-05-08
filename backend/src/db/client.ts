import { createClient, type Client } from "@libsql/client";
import { drizzle, type LibSQLDatabase } from "drizzle-orm/libsql";
import * as schema from "./schema.js";

let tursoClient: Client | null = null;
let db: LibSQLDatabase<typeof schema> | null = null;

function readRequiredEnv(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

export function getTursoClient(): Client {
  if (tursoClient) {
    return tursoClient;
  }

  tursoClient = createClient({
    url: readRequiredEnv("TURSO_DATABASE_URL"),
    authToken: readRequiredEnv("TURSO_AUTH_TOKEN"),
  });

  return tursoClient;
}

export function getDb(): LibSQLDatabase<typeof schema> {
  if (db) {
    return db;
  }

  db = drizzle(getTursoClient(), { schema });

  return db;
}

export async function checkDatabaseConnection(): Promise<number> {
  const result = await getTursoClient().execute("select 1 as ok");
  const row = result.rows[0];

  return Number(row?.ok ?? 0);
}
