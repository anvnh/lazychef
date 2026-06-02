import { Hono } from "hono";
import { authMiddleware } from "../middleware/auth.js";
import {
  addFavoriteRecipe,
  listFavoriteRecipes,
  listMostViewedRecipes,
  RecipeGenerationError,
  recordRecipeView,
  removeFavoriteRecipe,
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

recipesRoutes.get("/favorites", async (context) => {
  try {
    const user = context.get("user");
    const recipes = await listFavoriteRecipes(user.id);

    return context.json({ recipes });
  } catch (error) {
    console.error("Favorite recipes list endpoint failed", error);
    return context.json({ error: "Could not load favorite recipes" }, 500);
  }
});

recipesRoutes.get("/most-viewed", async (context) => {
  try {
    const user = context.get("user");
    const recipes = await listMostViewedRecipes(user.id);

    return context.json({ recipes });
  } catch (error) {
    console.error("Most viewed recipes endpoint failed", error);
    return context.json({ error: "Could not load most viewed recipes" }, 500);
  }
});

recipesRoutes.post("/:recipeId/views", async (context) => {
  try {
    const user = context.get("user");
    const recipeId = context.req.param("recipeId").trim();

    if (!recipeId) {
      return context.json({ error: "Recipe id is required" }, 400);
    }

    const recipe = await recordRecipeView({
      userId: user.id,
      recipeSuggestionId: recipeId,
    });

    if (!recipe) {
      return context.json({ error: "Recipe not found" }, 404);
    }

    return context.json({ recipe });
  } catch (error) {
    console.error("Recipe view endpoint failed", error);
    return context.json({ error: "Could not record recipe view" }, 500);
  }
});

recipesRoutes.post("/favorites/:recipeId", async (context) => {
  try {
    const user = context.get("user");
    const recipeId = context.req.param("recipeId").trim();

    if (!recipeId) {
      return context.json({ error: "Recipe id is required" }, 400);
    }

    const recipe = await addFavoriteRecipe({
      userId: user.id,
      recipeSuggestionId: recipeId,
    });

    if (!recipe) {
      return context.json({ error: "Recipe not found" }, 404);
    }

    return context.json({ recipe }, 201);
  } catch (error) {
    console.error("Favorite recipe create endpoint failed", error);
    return context.json({ error: "Could not save favorite recipe" }, 500);
  }
});

recipesRoutes.delete("/favorites/:recipeId", async (context) => {
  try {
    const user = context.get("user");
    const recipeId = context.req.param("recipeId").trim();

    if (!recipeId) {
      return context.json({ error: "Recipe id is required" }, 400);
    }

    await removeFavoriteRecipe({
      userId: user.id,
      recipeSuggestionId: recipeId,
    });

    return context.json({ ok: true });
  } catch (error) {
    console.error("Favorite recipe delete endpoint failed", error);
    return context.json({ error: "Could not remove favorite recipe" }, 500);
  }
});
