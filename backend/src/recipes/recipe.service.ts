import { randomUUID } from "node:crypto";
import { desc, eq } from "drizzle-orm";
import { readOptionalEnv, readRequiredEnv } from "../config/env.js";
import { getDb } from "../db/client.js";
import { detectedIngredients, recipeSuggestions, scans } from "../db/schema.js";

const defaultGeminiModel = "gemini-2.5-flash";
const geminiApiBaseUrl = "https://generativelanguage.googleapis.com/v1beta";
const googleCustomSearchUrl = "https://www.googleapis.com/customsearch/v1";

type GeminiGenerateContentResponse = {
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string;
      }>;
    };
  }>;
  error?: {
    message?: string;
  };
};

type GoogleImageSearchResponse = {
  items?: Array<{
    link?: string;
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
  void updateRecipeSuggestionImageUrls(recipesToInsert);

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
    queueMissingRecipeImageUrls(existingRecipes);
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

export async function listRecipeSuggestionsForScan(
  scanId: string,
): Promise<RecipeSuggestionResult[]> {
  const rows = await getDb()
    .select()
    .from(recipeSuggestions)
    .where(eq(recipeSuggestions.scanId, scanId));

  return rows.map(toRecipeSuggestionResult);
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
  const model = normalizeModelName(
    readOptionalEnv("GEMINI_MODEL", defaultGeminiModel),
  );
  const response = await fetch(
    `${geminiApiBaseUrl}/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": readRequiredEnv("GEMINI_API_KEY"),
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [
              {
                text:
                  "You are a cooking assistant.\n" +
                  `Given these available ingredients: ${ingredientNames.join(", ")}\n\n` +
                  "Suggest 5 recipes using ONLY or MOSTLY these ingredients.\n" +
                  "Return ONLY a valid JSON array, no markdown, no explanation.\n" +
                  "Each object must have:\n" +
                  "- title: string\n" +
                  "- description: one sentence summary\n" +
                  "- instructions: full step by step as a single string\n" +
                  '- cookingTime: string e.g. "20 minutes"\n' +
                  '- difficulty: "easy" | "medium" | "hard"\n' +
                  "- missingIngredients: string array of common ingredients needed but not available, keep minimal",
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.4,
          responseMimeType: "application/json",
        },
      }),
    },
  );
  const payload = (await response
    .json()
    .catch(() => null)) as GeminiGenerateContentResponse | null;

  if (!response.ok) {
    throw new RecipeGenerationError(
      payload?.error?.message ?? "Gemini recipe generation failed",
    );
  }

  const text = payload?.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? "")
    .join("")
    .trim();

  if (!text) {
    throw new RecipeGenerationError("Gemini returned an empty recipe response");
  }

  return normalizeRecipes(parseRecipeResponse(text));
}

function parseRecipeResponse(text: string): unknown {
  try {
    return JSON.parse(text) as unknown;
  } catch {
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      throw new RecipeGenerationError("Gemini returned non-JSON recipes");
    }

    try {
      return JSON.parse(jsonMatch[0]) as unknown;
    } catch {
      throw new RecipeGenerationError("Gemini returned malformed recipe JSON");
    }
  }
}

function normalizeRecipes(value: unknown): GeneratedRecipe[] {
  if (!Array.isArray(value)) {
    throw new RecipeGenerationError("Gemini recipe response was not an array");
  }

  return value
    .map((recipe) => {
      if (!recipe || typeof recipe !== "object") {
        return null;
      }

      const item = recipe as Record<string, unknown>;
      const title = readString(item.title);
      const description = readString(item.description);
      const instructions = readString(item.instructions);
      const cookingTime = readString(item.cookingTime);
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

function queueMissingRecipeImageUrls(
  recipes: RecipeImageUpdateCandidate[],
): void {
  const recipesWithoutImages = recipes.filter((recipe) => !recipe.imageUrl);

  if (recipesWithoutImages.length === 0) {
    return;
  }

  void updateRecipeSuggestionImageUrls(recipesWithoutImages);
}

async function fetchRecipeImageUrl(
  recipeTitle: string,
): Promise<string | null> {
  const apiKey = readOptionalEnv("GOOGLE_CUSTOM_SEARCH_API_KEY", "");
  const cx = readOptionalEnv("GOOGLE_CUSTOM_SEARCH_CX", "");

  if (!apiKey || !cx) {
    return null;
  }

  const url = new URL(googleCustomSearchUrl);
  url.searchParams.set("key", apiKey);
  url.searchParams.set("cx", cx);
  url.searchParams.set("q", `${recipeTitle} food`);
  url.searchParams.set("searchType", "image");
  url.searchParams.set("num", "1");

  try {
    const response = await fetch(url);
    const payload = (await response
      .json()
      .catch(() => null)) as GoogleImageSearchResponse | null;

    if (!response.ok) {
      console.error(
        "Recipe image search failed",
        payload?.error?.message ?? response.statusText,
      );
      return null;
    }

    const imageUrl = payload?.items?.[0]?.link;
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

function normalizeModelName(model: string): string {
  return model.trim().replace(/^models\//, "") || defaultGeminiModel;
}
