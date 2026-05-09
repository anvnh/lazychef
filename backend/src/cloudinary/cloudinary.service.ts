import { v2 as cloudinary, type UploadApiResponse } from "cloudinary";
import { readOptionalEnv, readRequiredEnv } from "../config/env.js";
import type { UploadableImage } from "../scans/uploadable-image.js";

const defaultUploadFolder = "lazychef/scans";

export type CloudinaryUploadResult = {
  publicId: string;
  imageUrl: string;
  secureUrl: string;
  width: number;
  height: number;
  format: string;
  bytes: number;
};

export class CloudinaryUploadError extends Error {
  constructor(
    message: string,
    public readonly statusCode: 400 | 500 | 502 = 502,
  ) {
    super(message);
    this.name = "CloudinaryUploadError";
  }
}

export async function uploadImageToCloudinary(
  image: UploadableImage,
  userId: string,
): Promise<CloudinaryUploadResult> {
  configureCloudinary();

  const folder = `${readOptionalEnv("CLOUDINARY_UPLOAD_FOLDER", defaultUploadFolder)}/${userId}`;
  const buffer = Buffer.from(await image.arrayBuffer());
  const result = await uploadBufferToCloudinary(buffer, folder).catch(
    (error: unknown) => {
      const message =
        error instanceof Error ? error.message : "Cloudinary upload failed";

      throw new CloudinaryUploadError(message);
    },
  );

  return {
    publicId: result.public_id,
    imageUrl: result.secure_url,
    secureUrl: result.secure_url,
    width: Number(result.width ?? 0),
    height: Number(result.height ?? 0),
    format: result.format ?? "unknown",
    bytes: Number(result.bytes ?? image.size),
  };
}

function configureCloudinary(): void {
  cloudinary.config({
    cloud_name: readRequiredEnv("CLOUDINARY_CLOUD_NAME"),
    api_key: readRequiredEnv("CLOUDINARY_API_KEY"),
    api_secret: readRequiredEnv("CLOUDINARY_API_SECRET"),
    secure: true,
  });
}

function uploadBufferToCloudinary(
  buffer: Buffer,
  folder: string,
): Promise<UploadApiResponse> {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: "image",
      },
      (error, result) => {
        if (error) {
          reject(error);
          return;
        }

        if (!result) {
          reject(new Error("Cloudinary returned an empty response"));
          return;
        }

        resolve(result);
      },
    );

    uploadStream.end(buffer);
  });
}
