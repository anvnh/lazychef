# System Architecture

## Overview
LazyChef is an application that allows users to scan their fridge (using their camera or an image upload) to detect food ingredients. Based on the detected ingredients, the app suggests recipes. 

The system is split into two main components:
1. **Frontend**: A Flutter mobile application (Client).
2. **Backend**: A Node.js REST API built with Hono (Server).

---

## 1. Frontend (Flutter)

**Stack**: Flutter, Dart, Riverpod, go_router, Dio, freezed, json_serializable, flutter_secure_storage, image_picker.

**Responsibilities**:
- UI/UX and User Interactions.
- Capturing images via camera or gallery.
- Managing local auth state (JWT in secure storage).
- Displaying detected ingredients and suggested recipes.

**Architecture Paradigm**: Feature-First (Layered within features)
```text
lib/
  core/               # App-wide configurations
    api/              # Dio client setup, interceptors
    router/           # go_router configuration
    theme/            # App theme, colors, typography
    utils/            # Helpers (formatters, validators)
  features/
    auth/
      data/           # Repositories, API calls
      models/         # Freezed data classes
      providers/      # Riverpod state management
      ui/             # Screens and widgets
    scan/
      data/
      models/
      providers/
      ui/
    history/
      data/
      models/
      providers/
      ui/
```

---

## 2. Backend (Node.js)

**Stack**: Node.js, TypeScript, Hono, Drizzle ORM, Turso (libSQL), JWT, bcrypt/argon2, Cloudinary SDK, AI Vision Provider (e.g., OpenAI Vision or Google Cloud Vision).

**Responsibilities**:
- Authentication & Authorization (JWT issuance).
- Secure password hashing.
- Cloudinary secure uploads / signing.
- Calling external Vision APIs to detect ingredients.
- Suggesting recipes based on ingredients.
- Database reads and writes (Turso).

**Folder Structure**:
```text
backend/
  src/
    db/               # Drizzle schema, Turso connection setup
    auth/             # Auth logic, JWT issuance, password hashing
    users/            # User CRUD operations
    scans/            # Scan history and saving records
    recipes/          # Recipe generation logic
    cloudinary/       # Cloudinary integration / upload helpers
    vision/           # Vision API integration (ingredient detection)
    middleware/       # Auth guards, error handlers
    routes/           # Hono route definitions
    utils/            # Helper functions
    index.ts          # Server entry point
```

---

## 3. Database Schema (Drizzle ORM)

The database is hosted on Turso and interacted with via Drizzle ORM.

### `users`
- `id` (text/uuid, primary key)
- `email` (text, unique)
- `password_hash` (text)
- `created_at` (timestamp)

### `scans`
- `id` (text/uuid, primary key)
- `user_id` (text, foreign key -> users.id)
- `image_url` (text) - Cloudinary URL
- `created_at` (timestamp)

### `detected_ingredients`
- `id` (text/uuid, primary key)
- `scan_id` (text, foreign key -> scans.id)
- `name` (text)
- `confidence` (real/optional)

### `recipe_suggestions`
- `id` (text/uuid, primary key)
- `scan_id` (text, foreign key -> scans.id)
- `title` (text)
- `description` (text)
- `instructions` (text)

---

## 4. Workflows

**Auth Flow**:
1. User submits email/password to `/api/auth/register` or `/api/auth/login`.
2. Backend processes with bcrypt/argon2, saves to Turso, returns JWT.
3. Flutter saves JWT in `flutter_secure_storage`.
4. Subsequent requests include `Authorization: Bearer <JWT>`.

**Scan Flow**:
1. Flutter uses `image_picker` to get a photo.
2. Flutter posts the image to `/api/scans/upload`.
3. Backend uploads the image to Cloudinary.
4. Backend sends the Cloudinary URL (or image buffer) to the Vision API to detect ingredients.
5. Backend uses the detected ingredients to query a Recipe/LLM API for recipes.
6. Backend saves the `scan`, `detected_ingredients`, and `recipe_suggestions` to Turso.
7. Backend responds to Flutter with the full parsed payload.
8. Flutter displays the results.
