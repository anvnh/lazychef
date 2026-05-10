import { sql } from "drizzle-orm";
import { real, sqliteTable, text } from "drizzle-orm/sqlite-core";

export const users = sqliteTable("users", {
  id: text("id").primaryKey(),
  email: text("email").notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  createdAt: text("created_at")
    .notNull()
    .default(sql`CURRENT_TIMESTAMP`),
});

export const scans = sqliteTable("scans", {
  id: text("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  imageUrl: text("image_url").notNull(),
  createdAt: text("created_at")
    .notNull()
    .default(sql`CURRENT_TIMESTAMP`),
});

export const detectedIngredients = sqliteTable("detected_ingredients", {
  id: text("id").primaryKey(),
  scanId: text("scan_id")
    .notNull()
    .references(() => scans.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  confidence: real("confidence"),
});

export const recipeSuggestions = sqliteTable("recipe_suggestions", {
  id: text("id").primaryKey(),
  scanId: text("scan_id")
    .notNull()
    .references(() => scans.id, { onDelete: "cascade" }),
  title: text("title").notNull(),
  description: text("description").notNull(),
  instructions: text("instructions").notNull(),
  cookingTime: text("cooking_time"),
  difficulty: text("difficulty", { enum: ["easy", "medium", "hard"] }),
  missingIngredients: text("missing_ingredients"),
  imageUrl: text("image_url"),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
