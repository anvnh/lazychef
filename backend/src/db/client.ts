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

export async function ensureDatabaseSchema(): Promise<void> {
  const recipeColumns = await getTursoClient().execute(
    "PRAGMA table_info(recipe_suggestions)",
  );
  const hasImageUrl = recipeColumns.rows.some(
    (row) => row.name === "image_url",
  );
  const hasViewCount = recipeColumns.rows.some(
    (row) => row.name === "view_count",
  );

  if (!hasImageUrl) {
    await getTursoClient().execute(
      "ALTER TABLE recipe_suggestions ADD COLUMN image_url TEXT",
    );
  }

  if (!hasViewCount) {
    await getTursoClient().execute(
      "ALTER TABLE recipe_suggestions ADD COLUMN view_count INTEGER NOT NULL DEFAULT 0",
    );
  }

  const ingredientColumns = await getTursoClient().execute(
    "PRAGMA table_info(detected_ingredients)",
  );
  const hasQuantity = ingredientColumns.rows.some(
    (row) => row.name === "quantity",
  );
  const hasExpiryDate = ingredientColumns.rows.some(
    (row) => row.name === "expiry_date",
  );

  if (!hasQuantity) {
    await getTursoClient().execute(
      "ALTER TABLE detected_ingredients ADD COLUMN quantity TEXT",
    );
  }

  if (!hasExpiryDate) {
    await getTursoClient().execute(
      "ALTER TABLE detected_ingredients ADD COLUMN expiry_date TEXT",
    );
  }

  await getTursoClient().execute(`
    CREATE TABLE IF NOT EXISTS favorite_recipes (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      recipe_suggestion_id TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (recipe_suggestion_id) REFERENCES recipe_suggestions(id) ON DELETE CASCADE
    )
  `);
  await getTursoClient().execute(`
    CREATE UNIQUE INDEX IF NOT EXISTS favorite_recipes_user_recipe_unique
    ON favorite_recipes(user_id, recipe_suggestion_id)
  `);
}
