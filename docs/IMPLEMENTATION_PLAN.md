# Implementation Plan

## Phase 1: Foundation (Backend)
- [ ] Initialize Node.js + TypeScript project.
- [ ] Set up Hono and test a basic `/ping` endpoint.
- [ ] Configure Turso database connection.
- [ ] Set up Drizzle ORM and define the database schema.
- [ ] Run initial database migrations.

## Phase 2: Auth API & Backend Core
- [ ] Implement user registration & login routes.
- [ ] Add password hashing (argon2 or bcrypt).
- [ ] Add JWT generation and validation middleware.
- [ ] Set up Cloudinary SDK for image uploads.

## Phase 3: Vision & Recipe Engine
- [ ] Integrate Vision API for ingredient detection.
- [ ] Integrate Recipe API/LLM for recipe generation.
- [ ] Create the main `/api/scans` endpoint to handle the complete image -> ingredient -> recipe pipeline.
- [ ] Save the pipeline results to the Turso database.

## Phase 4: Foundation (Frontend)
- [ ] Initialize Flutter project.
- [ ] Set up routing using `go_router`.
- [ ] Configure `Dio` for network requests (add base URL, interceptors for JWT).
- [ ] Setup Riverpod and secure storage.

## Phase 5: Auth UI
- [ ] Create Login and Registration screens.
- [ ] Implement Auth provider state management.
- [ ] Wire up UI to backend Auth API.

## Phase 6: Core App UI
- [ ] Create Home screen with camera/gallery access (`image_picker`).
- [ ] Build the Scan Results screen to show detected ingredients and recipes.
- [ ] Build the History screen to fetch and display past scans from the backend.
