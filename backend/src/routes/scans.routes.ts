import type { Context } from "hono";
import { Hono } from "hono";
import {
  CloudinaryUploadError,
  uploadImageToCloudinary,
} from "../cloudinary/cloudinary.service.js";
import { authMiddleware } from "../middleware/auth.js";
import type { UploadableImage } from "../scans/uploadable-image.js";
import {
  analyzeScanImage,
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
    const uploadPromise = uploadImageToCloudinary(image, user.id);
    const analysisPromise = analyzeScanImage(image);
    const [uploadResult, analysisResult] = await Promise.allSettled([
      uploadPromise,
      analysisPromise,
    ]);

    if (uploadResult.status === "rejected") {
      return handleScanError(context, uploadResult.reason);
    }

    const analysis =
      analysisResult.status === "fulfilled"
        ? analysisResult.value
        : toFailedAnalysis(analysisResult.reason);

    return context.json({ image: uploadResult.value, analysis }, 201);
  } catch (error) {
    return handleScanError(context, error);
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

function toFailedAnalysis(error: unknown): VisionAnalysisResult {
  const message =
    error instanceof Error ? error.message : "Gemini image analysis failed";

  return {
    provider: "gemini",
    model: (process.env.GEMINI_MODEL || "gemini-2.5-flash").replace(
      /^models\//,
      "",
    ),
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
