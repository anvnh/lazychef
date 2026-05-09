import { randomUUID } from "node:crypto";
import type { CloudinaryUploadResult } from "../cloudinary/cloudinary.service.js";
import { getDb } from "../db/client.js";
import { detectedIngredients, scans } from "../db/schema.js";
import type { DetectedIngredient } from "../vision/vision.service.js";

export type SavedScan = {
  id: string;
  userId: string;
  imageUrl: string;
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
