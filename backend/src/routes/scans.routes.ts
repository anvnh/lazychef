import type { Context } from "hono";
import { Hono } from "hono";
import {
  CloudinaryUploadError,
  uploadImageToCloudinary,
} from "../cloudinary/cloudinary.service.js";
import { authMiddleware } from "../middleware/auth.js";
import { queueRecipeSuggestionsForScan } from "../recipes/recipe.service.js";
import {
  listUserScanHistory,
  replaceScanIngredients,
  saveScanResult,
  type EditableIngredient,
} from "../scans/scan.service.js";
import type { UploadableImage } from "../scans/uploadable-image.js";
import {
  analyzeScanImageUrl,
  cloudflareVisionModel,
  VisionAnalysisError,
  type VisionAnalysisResult,
} from "../vision/vision.service.js";

const allowedImageTypes = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);
const maxImageSizeBytes = 8 * 1024 * 1024;

export const scansRoutes = new Hono();

scansRoutes.use("*", authMiddleware);

scansRoutes.get("/history", async (context) => {
  try {
    const user = context.get("user");
    const history = await listUserScanHistory(user.id);

    return context.json({ history });
  } catch {
    return context.json({ error: "Could not load scan history" }, 500);
  }
});

scansRoutes.post("/upload", async (context) => {
  const body = await context.req.parseBody().catch(() => null);
  const image = body?.image;

  if (!isUploadableImage(image)) {
    return context.json({ error: "Expected multipart image file" }, 400);
  }

  if (!allowedImageTypes.has(image.type)) {
    return context.json({ error: "Unsupported image type" }, 415);
  }

  if (image.size > maxImageSizeBytes) {
    return context.json({ error: "Image must be 8MB or smaller" }, 413);
  }

  try {
    const user = context.get("user");
    const uploadResult = await uploadImageToCloudinary(image, user.id);
    const imageUrl = uploadResult.secureUrl || uploadResult.imageUrl;
    const analysisResult = await analyzeScanImageUrl(imageUrl, image).then(
      (analysis) => ({ status: "fulfilled" as const, value: analysis }),
      (reason: unknown) => ({ status: "rejected" as const, reason }),
    );

    const analysis =
      analysisResult.status === "fulfilled"
        ? analysisResult.value
        : toFailedAnalysis(analysisResult.reason);

    const scan = await saveScanResult({
      userId: user.id,
      image: uploadResult,
      detectedIngredients: analysis.detectedIngredients,
    });

    queueRecipeSuggestionsForScan(
      scan.id,
      analysis.detectedIngredients.map((ingredient) => ingredient.name),
    );

    return context.json({ scan, image: uploadResult, analysis }, 201);
  } catch (error) {
    return handleScanError(context, error);
  }
});

scansRoutes.put("/:scanId/ingredients", async (context) => {
  const scanId = context.req.param("scanId").trim();
  if (!scanId) {
    return context.json({ error: "Scan id is required" }, 400);
  }

  const body = await context.req.json().catch(() => null);
  const ingredients = parseEditableIngredients(body);
  if (!ingredients) {
    return context.json({ error: "Expected ingredients array" }, 400);
  }

  try {
    const user = context.get("user");
    const updatedIngredients = await replaceScanIngredients({
      scanId,
      userId: user.id,
      ingredients,
    });

    if (!updatedIngredients) {
      return context.json({ error: "Scan not found" }, 404);
    }

    queueRecipeSuggestionsForScan(
      scanId,
      updatedIngredients.map((ingredient) => ingredient.name),
    );

    return context.json({ ingredients: updatedIngredients });
  } catch (error) {
    console.error("Scan ingredient update failed", error);
    return context.json({ error: "Could not update scan ingredients" }, 500);
  }
});

function isUploadableImage(value: unknown): value is UploadableImage {
  return (
    typeof Blob !== "undefined" &&
    value instanceof Blob &&
    typeof value.type === "string" &&
    typeof value.size === "number"
  );
}

function parseEditableIngredients(body: unknown): EditableIngredient[] | null {
  if (!body || typeof body !== "object" || !("ingredients" in body)) {
    return null;
  }

  const ingredients = (body as { ingredients?: unknown }).ingredients;
  if (!Array.isArray(ingredients) || ingredients.length > 50) {
    return null;
  }

  const parsed: EditableIngredient[] = [];
  for (const ingredient of ingredients) {
    if (!ingredient || typeof ingredient !== "object") {
      return null;
    }

    const name = (ingredient as { name?: unknown }).name;
    const confidence = (ingredient as { confidence?: unknown }).confidence;

    if (typeof name !== "string") {
      return null;
    }

    if (
      confidence !== undefined &&
      confidence !== null &&
      (typeof confidence !== "number" || !Number.isFinite(confidence))
    ) {
      return null;
    }

    parsed.push({
      name,
      confidence: confidence ?? null,
    });
  }

  return parsed;
}

function toFailedAnalysis(error: unknown): VisionAnalysisResult {
  const message =
    error instanceof Error ? error.message : "Cloudflare image analysis failed";

  return {
    provider: "cloudflare",
    model: cloudflareVisionModel,
    status: "failed",
    detectedIngredients: [],
    message,
  };
}

function handleScanError(context: Context, error: unknown) {
  if (error instanceof CloudinaryUploadError) {
    return context.json({ error: error.message }, error.statusCode);
  }

  if (error instanceof VisionAnalysisError) {
    return context.json({ error: error.message }, error.statusCode);
  }

  return context.json({ error: "Unexpected scan upload error" }, 500);
}
