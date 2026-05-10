import type { UploadableImage } from "../scans/uploadable-image.js";
import { readRequiredEnv } from "../config/env.js";

export const cloudflareVisionModel = "@cf/meta/llama-3.2-11b-vision-instruct";

export type DetectedIngredient = {
  name: string;
  confidence: number;
};

export type VisionAnalysisResult = {
  provider: "cloudflare";
  model: string;
  status: "completed" | "failed";
  detectedIngredients: DetectedIngredient[];
  message: string;
};

type CloudflareAiResponse = {
  success?: boolean;
  result?: unknown;
  errors?: Array<{
    message?: string;
  }>;
};

type CloudflareIngredientResponse = {
  ingredients?: unknown;
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

export async function acceptCloudflareVisionModelAgreement(): Promise<void> {
  const response = await runCloudflareVisionModel({ prompt: "agree" });

  if (!response.ok) {
    const payload = (await response
      .json()
      .catch(() => null)) as CloudflareAiResponse | null;
    console.error(
      "Cloudflare model agreement call failed",
      readCloudflareError(payload) ?? response.statusText,
    );
  }
}

export async function analyzeScanImageUrl(
  imageUrl: string,
  fallbackImage?: UploadableImage,
): Promise<VisionAnalysisResult> {
  const imageDataUri = await readImageDataUri(imageUrl, fallbackImage);
  let payload = await requestCloudflareAnalysis(imageDataUri);
  const errorMessage = readCloudflareError(payload);

  if (errorMessage && isModelAgreementError(errorMessage)) {
    await acceptCloudflareVisionModelAgreement();
    payload = await requestCloudflareAnalysis(imageDataUri);
  }

  const finalErrorMessage = readCloudflareError(payload);
  if (finalErrorMessage) {
    throw new VisionAnalysisError(finalErrorMessage);
  }

  const parsed = extractCloudflareIngredientResponse(payload?.result);
  const detectedIngredients = normalizeIngredients(parsed.ingredients);

  return {
    provider: "cloudflare",
    model: cloudflareVisionModel,
    status: "completed",
    detectedIngredients,
    message: `Cloudflare detected ${detectedIngredients.length} visible ingredients.`,
  };
}

async function requestCloudflareAnalysis(
  imageDataUri: string,
): Promise<CloudflareAiResponse | null> {
  const response = await runCloudflareVisionModel({
    prompt:
      "Analyze this image and return ONLY a JSON object with this exact structure, no markdown, no explanation: " +
      '{"ingredients": ["ingredient1", "ingredient2"]}',
    image: imageDataUri,
    max_tokens: 256,
    temperature: 0,
  });
  const payload = (await response
    .json()
    .catch(() => null)) as CloudflareAiResponse | null;

  if (!response.ok && payload) {
    return payload;
  }

  return payload;
}

async function runCloudflareVisionModel(body: unknown): Promise<Response> {
  return fetch(
    `https://api.cloudflare.com/client/v4/accounts/${readRequiredEnv(
      "CLOUDFLARE_ACCOUNT_ID",
    )}/ai/run/${cloudflareVisionModel}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${readRequiredEnv("CLOUDFLARE_AUTH_TOKEN")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
}

function readCloudflareError(payload: CloudflareAiResponse | null): string {
  if (!payload) {
    return "Cloudflare image analysis failed";
  }

  if (payload.success === false) {
    return payload.errors?.[0]?.message ?? "Cloudflare image analysis failed";
  }

  return "";
}

function isModelAgreementError(message: string): boolean {
  return message.toLowerCase().includes("model agreement");
}

async function readImageDataUri(
  imageUrl: string,
  fallbackImage?: UploadableImage,
): Promise<string> {
  try {
    return await fetchImageAsDataUri(imageUrl);
  } catch (error) {
    if (!fallbackImage) {
      throw error;
    }

    return uploadableImageAsDataUri(fallbackImage);
  }
}

async function fetchImageAsDataUri(imageUrl: string): Promise<string> {
  let lastStatus = 0;

  for (let attempt = 0; attempt < 3; attempt += 1) {
    const response = await fetch(imageUrl);
    lastStatus = response.status;

    if (!response.ok) {
      await delay(300 * (attempt + 1));
      continue;
    }

    const contentType = normalizeImageContentType(
      response.headers.get("content-type"),
    );
    const imageBase64 = Buffer.from(await response.arrayBuffer()).toString(
      "base64",
    );

    return `data:${contentType};base64,${imageBase64}`;
  }

  throw new VisionAnalysisError(
    `Could not fetch uploaded image from Cloudinary (${lastStatus || "unknown status"})`,
    502,
  );
}

async function uploadableImageAsDataUri(
  image: UploadableImage,
): Promise<string> {
  return `data:${normalizeImageContentType(image.type)};base64,${Buffer.from(
    await image.arrayBuffer(),
  ).toString("base64")}`;
}

function normalizeImageContentType(contentType: string | null): string {
  if (!contentType) {
    return "image/jpeg";
  }

  const [type] = contentType.split(";");
  const normalized = type.trim().toLowerCase();

  if (!normalized.startsWith("image/")) {
    return "image/jpeg";
  }

  return normalized === "image/jpg" ? "image/jpeg" : normalized;
}

async function delay(milliseconds: number): Promise<void> {
  await new Promise((resolve) => {
    setTimeout(resolve, milliseconds);
  });
}

function extractCloudflareIngredientResponse(
  result: unknown,
): CloudflareIngredientResponse {
  const response = readCloudflareResponse(result);

  if (!response) {
    throw new VisionAnalysisError(
      "Cloudflare returned an empty analysis response",
    );
  }

  if (typeof response === "object") {
    return response as CloudflareIngredientResponse;
  }

  if (typeof response === "string") {
    return parseCloudflareIngredientResponse(response);
  }

  throw new VisionAnalysisError(
    "Cloudflare returned unsupported analysis output",
  );
}

function readCloudflareResponse(result: unknown): unknown {
  if (typeof result === "string") {
    return result.trim();
  }

  if (!result || typeof result !== "object") {
    return null;
  }

  const record = result as Record<string, unknown>;
  const directText = record.response ?? record.text ?? record.output;

  if (typeof directText === "string") {
    return directText.trim();
  }

  if (directText && typeof directText === "object") {
    return directText;
  }

  if (Array.isArray(directText)) {
    const text = directText
      .map(readCloudflareResponse)
      .filter((item): item is string => typeof item === "string")
      .join("\n");

    return text || null;
  }

  return null;
}

function parseCloudflareIngredientResponse(
  text: string,
): CloudflareIngredientResponse {
  try {
    return JSON.parse(text) as CloudflareIngredientResponse;
  } catch {
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new VisionAnalysisError(
        "Cloudflare returned non-JSON analysis output",
      );
    }

    try {
      return JSON.parse(jsonMatch[0]) as CloudflareIngredientResponse;
    } catch {
      throw new VisionAnalysisError(
        "Cloudflare returned malformed JSON output",
      );
    }
  }
}

function normalizeIngredients(ingredients: unknown): DetectedIngredient[] {
  if (!Array.isArray(ingredients)) {
    return [];
  }

  return Array.from(
    new Set(
      ingredients
        .map(readIngredientName)
        .map((name) => name.trim().toLowerCase())
        .filter(Boolean),
    ),
  )
    .map((name) => ({
      name,
      confidence: 1,
    }))
    .slice(0, 20);
}

function readIngredientName(value: unknown): string {
  if (typeof value === "string") {
    return value;
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return typeof record.name === "string" ? record.name : "";
  }

  return "";
}
