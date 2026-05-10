import { randomUUID } from "node:crypto";
import { and, desc, eq } from "drizzle-orm";
import { readOptionalEnv, readRequiredEnv } from "../config/env.js";
import { getDb } from "../db/client.js";
import {
  detectedIngredients,
  favoriteRecipes,
  recipeSuggestions,
  scans,
} from "../db/schema.js";

const cloudflareRecipeModel = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
const pexelsSearchUrl = "https://api.pexels.com/v1/search";

type CloudflareTextGenerationResponse = {
  success?: boolean;
  result?: {
    response?: unknown;
  };
  errors?: Array<{
    message?: string;
  }>;
};

type PexelsImageSearchResponse = {
  photos?: Array<{
    src?: {
      medium?: string;
    };
  }>;
  error?: {
    message?: string;
  };
};

type RecipeImageUpdateCandidate = {
  id: string;
  title: string;
  imageUrl?: string | null;
};

type GeneratedRecipe = {
  title: string;
  description: string;
  instructions: string;
  cookingTime: string;
  difficulty: "easy" | "medium" | "hard";
  missingIngredients: string[];
};

export type RecipeSuggestionResult = GeneratedRecipe & {
  id: string;
  scanId: string;
  imageUrl: string | null;
};

export type RecipeIngredientResult = {
  name: string;
  confidence: number;
};

export type SuggestedRecipesResult = {
  recipes: RecipeSuggestionResult[];
  ingredients: RecipeIngredientResult[];
  retryable?: boolean;
};

const recipeGenerationJobs = new Map<
  string,
  Promise<RecipeSuggestionResult[]>
>();

export class RecipeGenerationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RecipeGenerationError";
  }
}

export async function generateAndSaveRecipeSuggestions(
  scanId: string,
  ingredientNames: string[],
): Promise<RecipeSuggestionResult[]> {
  const normalizedIngredients = normalizeIngredientNames(ingredientNames);

  if (normalizedIngredients.length === 0) {
    return [];
  }

  const runningJob = recipeGenerationJobs.get(scanId);
  if (runningJob) {
    return runningJob;
  }

  const existingRecipes = await listRecipeSuggestionsForScan(scanId);
  if (existingRecipes.length > 0) {
    return existingRecipes;
  }

  const queuedJob = recipeGenerationJobs.get(scanId);
  if (queuedJob) {
    return queuedJob;
  }

  const job = generateAndPersistRecipeSuggestions(
    scanId,
    normalizedIngredients,
  );
  recipeGenerationJobs.set(scanId, job);

  try {
    return await job;
  } finally {
    if (recipeGenerationJobs.get(scanId) === job) {
      recipeGenerationJobs.delete(scanId);
    }
  }
}

export function queueRecipeSuggestionsForScan(
  scanId: string,
  ingredientNames: string[],
): void {
  void generateAndSaveRecipeSuggestions(scanId, ingredientNames).catch(
    (error) => {
      console.error("Background recipe generation failed", error);
    },
  );
}

async function generateAndPersistRecipeSuggestions(
  scanId: string,
  normalizedIngredients: string[],
): Promise<RecipeSuggestionResult[]> {
  const generatedRecipes = await generateRecipes(normalizedIngredients);

  if (generatedRecipes.length === 0) {
    return [];
  }

  const currentIngredients = await getScanIngredientNames(scanId);
  if (!sameIngredients(normalizedIngredients, currentIngredients)) {
    return [];
  }

  const db = getDb();
  const recipesToInsert = generatedRecipes.map((recipe) => ({
    id: randomUUID(),
    scanId,
    title: recipe.title,
    description: recipe.description,
    instructions: recipe.instructions,
    cookingTime: recipe.cookingTime,
    difficulty: recipe.difficulty,
    missingIngredients: JSON.stringify(recipe.missingIngredients),
    imageUrl: null,
  }));

  await db.insert(recipeSuggestions).values(recipesToInsert);
  await updateRecipeSuggestionImageUrls(recipesToInsert);

  return recipesToInsert.map(toRecipeSuggestionResult);
}

export async function suggestRecipesForLatestScan(
  userId: string,
): Promise<SuggestedRecipesResult> {
  const latestScan = await getLatestUserScan(userId);

  if (!latestScan) {
    throw new RecipeGenerationError("No scan history found");
  }

  const ingredientRows = await getDb()
    .select()
    .from(detectedIngredients)
    .where(eq(detectedIngredients.scanId, latestScan.id));
  const ingredients = ingredientRows.map(toRecipeIngredientResult);

  const existingRecipes = await listRecipeSuggestionsForScan(latestScan.id);
  if (existingRecipes.length > 0) {
    await updateRecipeSuggestionImageUrls(existingRecipes);
    return { recipes: existingRecipes, ingredients };
  }

  try {
    const recipes = await generateAndSaveRecipeSuggestions(
      latestScan.id,
      ingredientRows.map((ingredient) => ingredient.name),
    );

    return { recipes, ingredients };
  } catch (error) {
    console.error("Recipe generation failed", error);
    return { recipes: [], ingredients, retryable: true };
  }
}

export async function listFavoriteRecipes(
  userId: string,
): Promise<RecipeSuggestionResult[]> {
  const rows = await getDb()
    .select({
      id: recipeSuggestions.id,
      scanId: recipeSuggestions.scanId,
      title: recipeSuggestions.title,
      description: recipeSuggestions.description,
      instructions: recipeSuggestions.instructions,
      cookingTime: recipeSuggestions.cookingTime,
      difficulty: recipeSuggestions.difficulty,
      missingIngredients: recipeSuggestions.missingIngredients,
      imageUrl: recipeSuggestions.imageUrl,
    })
    .from(favoriteRecipes)
    .innerJoin(
      recipeSuggestions,
      eq(favoriteRecipes.recipeSuggestionId, recipeSuggestions.id),
    )
    .innerJoin(scans, eq(recipeSuggestions.scanId, scans.id))
    .where(and(eq(favoriteRecipes.userId, userId), eq(scans.userId, userId)))
    .orderBy(desc(favoriteRecipes.createdAt));

  return rows.map(toRecipeSuggestionResult);
}

export async function addFavoriteRecipe(input: {
  userId: string;
  recipeSuggestionId: string;
}): Promise<RecipeSuggestionResult | null> {
  const recipe = await getUserRecipeSuggestion(
    input.userId,
    input.recipeSuggestionId,
  );

  if (!recipe) {
    return null;
  }

  await getDb()
    .insert(favoriteRecipes)
    .values({
      id: randomUUID(),
      userId: input.userId,
      recipeSuggestionId: input.recipeSuggestionId,
    })
    .onConflictDoNothing({
      target: [favoriteRecipes.userId, favoriteRecipes.recipeSuggestionId],
    });

  return recipe;
}

export async function removeFavoriteRecipe(input: {
  userId: string;
  recipeSuggestionId: string;
}): Promise<void> {
  await getDb()
    .delete(favoriteRecipes)
    .where(
      and(
        eq(favoriteRecipes.userId, input.userId),
        eq(favoriteRecipes.recipeSuggestionId, input.recipeSuggestionId),
      ),
    );
}

export async function listRecipeSuggestionsForScan(
  scanId: string,
): Promise<RecipeSuggestionResult[]> {
  const rows = await getDb()
    .select()
    .from(recipeSuggestions)
    .where(eq(recipeSuggestions.scanId, scanId));

  return rows.map(toRecipeSuggestionResult);
}

async function getUserRecipeSuggestion(
  userId: string,
  recipeSuggestionId: string,
): Promise<RecipeSuggestionResult | null> {
  const [recipe] = await getDb()
    .select({
      id: recipeSuggestions.id,
      scanId: recipeSuggestions.scanId,
      title: recipeSuggestions.title,
      description: recipeSuggestions.description,
      instructions: recipeSuggestions.instructions,
      cookingTime: recipeSuggestions.cookingTime,
      difficulty: recipeSuggestions.difficulty,
      missingIngredients: recipeSuggestions.missingIngredients,
      imageUrl: recipeSuggestions.imageUrl,
    })
    .from(recipeSuggestions)
    .innerJoin(scans, eq(recipeSuggestions.scanId, scans.id))
    .where(
      and(
        eq(recipeSuggestions.id, recipeSuggestionId),
        eq(scans.userId, userId),
      ),
    )
    .limit(1);

  return recipe ? toRecipeSuggestionResult(recipe) : null;
}

async function getLatestUserScan(userId: string) {
  const [latestScan] = await getDb()
    .select()
    .from(scans)
    .where(eq(scans.userId, userId))
    .orderBy(desc(scans.createdAt), desc(scans.id))
    .limit(1);

  return latestScan;
}

async function generateRecipes(
  ingredientNames: string[],
): Promise<GeneratedRecipe[]> {
  const response = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${readRequiredEnv(
      "CLOUDFLARE_ACCOUNT_ID",
    )}/ai/run/${cloudflareRecipeModel}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${readRequiredEnv("CLOUDFLARE_AUTH_TOKEN")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messages: [
          {
            role: "system",
            content:
              "You are a cooking assistant. Return strict JSON only. Do not include markdown, prose, code fences, or explanations.",
          },
          {
            role: "user",
            content:
              `Given these available ingredients: ${ingredientNames.join(", ")}\n\n` +
              "Suggest 5 recipes using ONLY or MOSTLY these ingredients.\n" +
              "Return ONLY a valid JSON array.\n" +
              "Each object must have:\n" +
              "- title: string\n" +
              "- description: one sentence summary\n" +
              "- instructions: full step by step as a single string\n" +
              '- cookingTime: string e.g. "20 minutes"\n' +
              '- difficulty: "easy" | "medium" | "hard"\n' +
              "- missingIngredients: string array of common ingredients needed but not available, keep minimal",
          },
        ],
        max_tokens: 1800,
        temperature: 0.3,
      }),
    },
  );
  const payload = (await response
    .json()
    .catch(() => null)) as CloudflareTextGenerationResponse | null;

  if (!response.ok || payload?.success === false) {
    throw new RecipeGenerationError(
      payload?.errors?.[0]?.message ?? "Cloudflare recipe generation failed",
    );
  }

  const text = readCloudflareRecipeResponse(payload?.result?.response);

  if (!text) {
    throw new RecipeGenerationError(
      "Cloudflare returned an empty recipe response",
    );
  }

  return normalizeRecipes(parseRecipeResponse(text));
}

function parseRecipeResponse(text: string): unknown {
  try {
    return JSON.parse(text) as unknown;
  } catch {
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      throw new RecipeGenerationError("Cloudflare returned non-JSON recipes");
    }

    try {
      return JSON.parse(jsonMatch[0]) as unknown;
    } catch {
      throw new RecipeGenerationError(
        "Cloudflare returned malformed recipe JSON",
      );
    }
  }
}

function normalizeRecipes(value: unknown): GeneratedRecipe[] {
  if (!Array.isArray(value)) {
    throw new RecipeGenerationError(
      "Cloudflare recipe response was not an array",
    );
  }

  return value
    .map((recipe) => {
      if (!recipe || typeof recipe !== "object") {
        return null;
      }

      const item = recipe as Record<string, unknown>;
      const title = readString(item.title);
      const description = readString(item.description);
      const instructions = readInstructions(item.instructions);
      const cookingTime = readCookingTime(item.cookingTime);
      const difficulty = normalizeDifficulty(item.difficulty);
      const missingIngredients = Array.isArray(item.missingIngredients)
        ? item.missingIngredients.map(readString).filter(Boolean)
        : [];

      if (!title || !description || !instructions || !cookingTime) {
        return null;
      }

      return {
        title,
        description,
        instructions,
        cookingTime,
        difficulty,
        missingIngredients,
      };
    })
    .filter((recipe): recipe is GeneratedRecipe => recipe !== null)
    .slice(0, 5);
}

function toRecipeSuggestionResult(
  recipe: typeof recipeSuggestions.$inferSelect,
): RecipeSuggestionResult {
  return {
    id: recipe.id,
    scanId: recipe.scanId,
    title: recipe.title,
    description: recipe.description,
    instructions: recipe.instructions,
    cookingTime: recipe.cookingTime ?? "",
    difficulty: normalizeDifficulty(recipe.difficulty),
    missingIngredients: parseMissingIngredients(recipe.missingIngredients),
    imageUrl: recipe.imageUrl,
  };
}

async function updateRecipeSuggestionImageUrls(
  recipes: RecipeImageUpdateCandidate[],
): Promise<void> {
  await Promise.all(
    recipes.map(async (recipe) => {
      const imageUrl = await fetchRecipeImageUrl(recipe.title);

      if (!imageUrl) {
        return;
      }

      try {
        await getDb()
          .update(recipeSuggestions)
          .set({ imageUrl })
          .where(eq(recipeSuggestions.id, recipe.id));

        recipe.imageUrl = imageUrl;
      } catch (error) {
        console.error("Recipe image URL update failed", error);
      }
    }),
  );
}

async function fetchRecipeImageUrl(
  recipeTitle: string,
): Promise<string | null> {
  const apiKey = readOptionalEnv("PEXELS_API_KEY", "");

  if (!apiKey) {
    return null;
  }

  const url = new URL(pexelsSearchUrl);
  url.searchParams.set("query", `${recipeTitle} food`);
  url.searchParams.set("per_page", "1");

  try {
    const response = await fetch(url, {
      headers: {
        Authorization: apiKey,
      },
    });
    const payload = (await response
      .json()
      .catch(() => null)) as PexelsImageSearchResponse | null;

    if (!response.ok) {
      console.error(
        "Recipe image search failed",
        payload?.error?.message ?? response.statusText,
      );
      return null;
    }

    const imageUrl = payload?.photos?.[0]?.src?.medium;
    return typeof imageUrl === "string" && imageUrl.trim()
      ? imageUrl.trim()
      : null;
  } catch (error) {
    console.error("Recipe image search failed", error);
    return null;
  }
}

function toRecipeIngredientResult(
  ingredient: typeof detectedIngredients.$inferSelect,
): RecipeIngredientResult {
  return {
    name: ingredient.name,
    confidence: Number(ingredient.confidence ?? 0),
  };
}

function normalizeIngredientNames(ingredientNames: string[]): string[] {
  return Array.from(
    new Set(
      ingredientNames
        .map((name) => name.trim().toLowerCase())
        .filter((name) => name.length > 0),
    ),
  );
}

async function getScanIngredientNames(scanId: string): Promise<string[]> {
  const rows = await getDb()
    .select({ name: detectedIngredients.name })
    .from(detectedIngredients)
    .where(eq(detectedIngredients.scanId, scanId));

  return normalizeIngredientNames(rows.map((ingredient) => ingredient.name));
}

function sameIngredients(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }

  const rightIngredients = new Set(right);
  return left.every((ingredient) => rightIngredients.has(ingredient));
}

function normalizeDifficulty(value: unknown): "easy" | "medium" | "hard" {
  return value === "medium" || value === "hard" ? value : "easy";
}

function parseMissingIngredients(value: string | null): string[] {
  if (!value) {
    return [];
  }

  try {
    const parsed = JSON.parse(value) as unknown;
    return Array.isArray(parsed) ? parsed.map(readString).filter(Boolean) : [];
  } catch {
    return [];
  }
}

function readString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function readInstructions(value: unknown): string {
  if (typeof value === "string") {
    return value.trim();
  }

  if (Array.isArray(value)) {
    return value
      .map(readString)
      .filter(Boolean)
      .map((step, index) => `${index + 1}. ${step}`)
      .join(" ");
  }

  return "";
}

function readCookingTime(value: unknown): string {
  if (typeof value === "number" && Number.isFinite(value)) {
    return `${value} minutes`;
  }

  return readString(value);
}

function readCloudflareRecipeResponse(value: unknown): string {
  if (typeof value === "string") {
    return value.trim();
  }

  if (Array.isArray(value) || (value && typeof value === "object")) {
    return JSON.stringify(value);
  }

  return "";
}
