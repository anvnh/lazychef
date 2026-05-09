import type { UploadableImage } from "../scans/uploadable-image.js";
import { readOptionalEnv, readRequiredEnv } from "../config/env.js";

const defaultGeminiModel = "gemini-2.5-flash";
const geminiApiBaseUrl = "https://generativelanguage.googleapis.com/v1beta";

export type DetectedIngredient = {
  name: string;
  confidence: number;
};

export type VisionAnalysisResult = {
  provider: "gemini";
  model: string;
  status: "completed" | "failed";
  detectedIngredients: DetectedIngredient[];
  message: string;
};

type GeminiIngredientResponse = {
  ingredients?: Array<{
    name?: unknown;
    confidence?: unknown;
  }>;
};

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

export class VisionAnalysisError extends Error {
  constructor(
    message: string,
    public readonly statusCode: 400 | 500 | 502 = 502,
  ) {
    super(message);
    this.name = "VisionAnalysisError";
  }
}

export async function analyzeScanImage(
  image: UploadableImage,
): Promise<VisionAnalysisResult> {
  const model = normalizeModelName(
    readOptionalEnv("GEMINI_MODEL", defaultGeminiModel),
  );
  const imageBase64 = Buffer.from(await image.arrayBuffer()).toString("base64");
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
                inline_data: {
                  mime_type: image.type || "image/jpeg",
                  data: imageBase64,
                },
              },
              {
                text:
                  "Identify visible food ingredients in this image. " +
                  "Return JSON only with this exact shape: " +
                  '{"ingredients":[{"name":"ingredient name","confidence":0.0}]}. ' +
                  "Use lowercase common ingredient names. " +
                  "Use confidence values from 0 to 1. " +
                  "Only include ingredients you can visually infer.",
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.2,
          responseMimeType: "application/json",
        },
      }),
    },
  );
  const payload = (await response
    .json()
    .catch(() => null)) as GeminiGenerateContentResponse | null;

  if (!response.ok) {
    throw new VisionAnalysisError(
      payload?.error?.message ?? "Gemini image analysis failed",
    );
  }

  const text = payload?.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? "")
    .join("")
    .trim();

  if (!text) {
    throw new VisionAnalysisError("Gemini returned an empty analysis response");
  }

  const parsed = parseGeminiIngredientResponse(text);
  const detectedIngredients = normalizeIngredients(parsed.ingredients ?? []);

  return {
    provider: "gemini",
    model,
    status: "completed",
    detectedIngredients,
    message: `Gemini detected ${detectedIngredients.length} visible ingredients.`,
  };
}

function parseGeminiIngredientResponse(text: string): GeminiIngredientResponse {
  try {
    return JSON.parse(text) as GeminiIngredientResponse;
  } catch {
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new VisionAnalysisError("Gemini returned non-JSON analysis output");
    }

    try {
      return JSON.parse(jsonMatch[0]) as GeminiIngredientResponse;
    } catch {
      throw new VisionAnalysisError("Gemini returned malformed JSON output");
    }
  }
}

function normalizeIngredients(
  ingredients: NonNullable<GeminiIngredientResponse["ingredients"]>,
): DetectedIngredient[] {
  return ingredients
    .map((ingredient) => {
      const name = typeof ingredient.name === "string" ? ingredient.name : "";
      const confidence = Number(ingredient.confidence);

      return {
        name: name.trim().toLowerCase(),
        confidence: Number.isFinite(confidence)
          ? Math.min(Math.max(confidence, 0), 1)
          : 0,
      };
    })
    .filter((ingredient) => ingredient.name.length > 0)
    .slice(0, 20);
}

function normalizeModelName(model: string): string {
  return model.trim().replace(/^models\//, "") || defaultGeminiModel;
}
