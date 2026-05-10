import { serve } from "@hono/node-server";
import "dotenv/config";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { checkDatabaseConnection, ensureDatabaseSchema } from "./db/client.js";
import { authRoutes } from "./routes/auth.routes.js";
import { recipesRoutes } from "./routes/recipes.routes.js";
import { scansRoutes } from "./routes/scans.routes.js";
import { acceptCloudflareVisionModelAgreement } from "./vision/vision.service.js";

const app = new Hono();

app.use("*", cors());

app.route("/api/auth", authRoutes);
app.route("/api/recipes", recipesRoutes);
app.route("/api/scans", scansRoutes);

app.get("/ping", (context) => {
  return context.json({
    message: "pong",
    service: "lazychef-backend",
  });
});

app.get("/db/health", async (context) => {
  try {
    const result = await checkDatabaseConnection();

    return context.json({
      ok: true,
      database: "connected",
      result,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown database error";

    return context.json(
      {
        ok: false,
        database: "disconnected",
        error: message,
      },
      500,
    );
  }
});

const port = Number(process.env.PORT ?? 3000);

await ensureDatabaseSchema().catch((error) => {
  console.error("Database schema check failed", error);
});
await acceptCloudflareVisionModelAgreement().catch((error) => {
  console.error("Cloudflare model agreement check failed", error);
});

serve({
  fetch: app.fetch,
  port,
});

console.log(`LazyChef backend listening on http://localhost:${port}`);
