import { Hono } from "hono";
import { authMiddleware } from "../middleware/auth.js";
import {
  RecipeGenerationError,
  suggestRecipesForLatestScan,
} from "../recipes/recipe.service.js";

export const recipesRoutes = new Hono();

recipesRoutes.use("*", authMiddleware);

recipesRoutes.get("/suggest", async (context) => {
  try {
    const user = context.get("user");
    const result = await suggestRecipesForLatestScan(user.id);

    return context.json(result);
  } catch (error) {
    if (
      error instanceof RecipeGenerationError &&
      error.message === "No scan history found"
    ) {
      return context.json({ error: error.message }, 400);
    }

    console.error("Recipe suggestion endpoint failed", error);
    return context.json({ recipes: [], ingredients: [], retryable: true });
  }
});
