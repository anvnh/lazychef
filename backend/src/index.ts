import { serve } from "@hono/node-server";
import "dotenv/config";
import { Hono } from "hono";
import { checkDatabaseConnection } from "./db/client.js";
import { authRoutes } from "./routes/auth.routes.js";

const app = new Hono();

app.route("/api/auth", authRoutes);

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

serve({
  fetch: app.fetch,
  port,
});

console.log(`LazyChef backend listening on http://localhost:${port}`);
