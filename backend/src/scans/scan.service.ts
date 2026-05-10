import { randomUUID } from "node:crypto";
import { desc, eq, inArray } from "drizzle-orm";
import type { CloudinaryUploadResult } from "../cloudinary/cloudinary.service.js";
import { getDb } from "../db/client.js";
import { detectedIngredients, recipeSuggestions, scans } from "../db/schema.js";
import type { DetectedIngredient } from "../vision/vision.service.js";

export type SavedScan = {
  id: string;
  userId: string;
  imageUrl: string;
  createdAt?: string;
};

export type RecipeSuggestion = {
  id: string;
  title: string;
  description: string;
  instructions: string;
  cookingTime: string;
  difficulty: "easy" | "medium" | "hard";
  missingIngredients: string[];
  imageUrl: string | null;
};

export type ScanHistoryItem = Required<SavedScan> & {
  detectedIngredients: DetectedIngredient[];
  recipeSuggestions: RecipeSuggestion[];
};

export async function saveScanResult(input: {
  userId: string;
  image: CloudinaryUploadResult;
  detectedIngredients: DetectedIngredient[];
}): Promise<SavedScan> {
  const db = getDb();
  const scanId = randomUUID();
  const imageUrl = input.image.secureUrl || input.image.imageUrl;

  await db.transaction(async (tx) => {
    await tx.insert(scans).values({
      id: scanId,
      userId: input.userId,
      imageUrl,
    });

    if (input.detectedIngredients.length === 0) {
      return;
    }

    await tx.insert(detectedIngredients).values(
      input.detectedIngredients.map((ingredient) => ({
        id: randomUUID(),
        scanId,
        name: ingredient.name,
        confidence: ingredient.confidence,
      })),
    );
  });

  return {
    id: scanId,
    userId: input.userId,
    imageUrl,
  };
}

export async function listUserScanHistory(
  userId: string,
): Promise<ScanHistoryItem[]> {
  const db = getDb();
  const scanRows = await db
    .select()
    .from(scans)
    .where(eq(scans.userId, userId))
    .orderBy(desc(scans.createdAt))
    .limit(50);

  if (scanRows.length === 0) {
    return [];
  }

  const scanIds = scanRows.map((scan) => scan.id);
  const [ingredientRows, recipeRows] = await Promise.all([
    db
      .select()
      .from(detectedIngredients)
      .where(inArray(detectedIngredients.scanId, scanIds)),
    db
      .select()
      .from(recipeSuggestions)
      .where(inArray(recipeSuggestions.scanId, scanIds)),
  ]);

  const ingredientsByScanId = new Map<string, DetectedIngredient[]>();
  for (const ingredient of ingredientRows) {
    const scanIngredients = ingredientsByScanId.get(ingredient.scanId) ?? [];
    scanIngredients.push({
      name: ingredient.name,
      confidence: Number(ingredient.confidence ?? 0),
    });
    ingredientsByScanId.set(ingredient.scanId, scanIngredients);
  }

  const recipesByScanId = new Map<string, RecipeSuggestion[]>();
  for (const recipe of recipeRows) {
    const scanRecipes = recipesByScanId.get(recipe.scanId) ?? [];
    scanRecipes.push({
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      instructions: recipe.instructions,
      cookingTime: recipe.cookingTime ?? "",
      difficulty:
        recipe.difficulty === "medium" || recipe.difficulty === "hard"
          ? recipe.difficulty
          : "easy",
      missingIngredients: parseMissingIngredients(recipe.missingIngredients),
      imageUrl: recipe.imageUrl,
    });
    recipesByScanId.set(recipe.scanId, scanRecipes);
  }

  return scanRows.map((scan) => ({
    id: scan.id,
    userId: scan.userId,
    imageUrl: scan.imageUrl,
    createdAt: scan.createdAt,
    detectedIngredients: ingredientsByScanId.get(scan.id) ?? [],
    recipeSuggestions: recipesByScanId.get(scan.id) ?? [],
  }));
}

function parseMissingIngredients(value: string | null): string[] {
  if (!value) {
    return [];
  }

  try {
    const parsed = JSON.parse(value) as unknown;
    return Array.isArray(parsed)
      ? parsed.filter((item): item is string => typeof item === "string")
      : [];
  } catch {
    return [];
  }
}
