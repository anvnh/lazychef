import type { UploadableImage } from "../scans/uploadable-image.js";

const placeholderVisionModel = "gemini-1.5-pro";

export type DetectedIngredient = {
  name: string;
  confidence: number;
};

export type VisionAnalysisResult = {
  provider: "placeholder";
  model: string;
  status: "pending";
  detectedIngredients: DetectedIngredient[];
  message: string;
};

export async function analyzeScanImage(
  image: UploadableImage,
): Promise<VisionAnalysisResult> {
  await Promise.resolve();

  return {
    provider: "placeholder",
    model: placeholderVisionModel,
    status: "pending",
    detectedIngredients: [],
    message:
      `AI image analysis placeholder received ${image.type || "unknown"} image. ` +
      "Gemini integration will replace this response.",
  };
}
