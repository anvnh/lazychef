# Tasks Tracker

Update this file by changing `[ ]` to `[x]` as you complete tasks.

## Backend
- [ ] Initialize Node + TS + Hono project (`backend/`).
- [ ] Install Drizzle ORM, Turso client, Hono, JWT, bcrypt.
- [ ] Create `db/schema.ts` with `users`, `scans`, `detected_ingredients`, `recipe_suggestions`.
- [ ] Implement `auth/auth.service.ts` (hash, compare, JWT).
- [ ] Create `routes/auth.routes.ts` (`/register`, `/login`).
- [ ] Create JWT middleware (`middleware/auth.ts`).
- [ ] Set up Cloudinary integration (`cloudinary/cloudinary.service.ts`).
- [ ] Set up Vision API integration (`vision/vision.service.ts`).
- [ ] Set up Recipe generation logic (`recipes/recipe.service.ts`).
- [ ] Create `routes/scans.routes.ts` (`POST /`, `GET /history`).
- [ ] Test API with mock data.

## Frontend
- [x] Create Flutter project.
- [ ] Add dependencies: `flutter_riverpod`, `go_router`, `dio`, `freezed`, `json_serializable`, `flutter_secure_storage`, `image_picker`.
- [ ] Set up code generation for `freezed`.
- [ ] Create `core/api/api_client.dart` with Dio and Auth Interceptors.
- [ ] Create `core/router/app_router.dart` with `go_router`.
- [ ] Create `features/auth/models/user.dart` (Freezed).
- [ ] Create `features/auth/data/auth_repository.dart`.
- [ ] Create `features/auth/providers/auth_provider.dart`.
- [x] Build `LoginScreen` and `RegisterScreen`.
- [ ] Create `features/scan/models/scan_result.dart` (Freezed).
- [ ] Create `features/scan/data/scan_repository.dart` (handles multipart image uploads).
- [ ] Create `features/scan/providers/scan_provider.dart`.
- [ ] Build `HomeScreen` with Image Picker.
- [x] Build `ScanResultScreen` (UI for ingredients + recipes).
- [ ] Build `HistoryScreen` mapping to `/api/scans/history`.

## Polish
- [ ] Handle loading states (CircularProgressIndicator).
- [ ] Handle API errors gracefully via SnackBar.
- [ ] Secure API keys in `.env` for backend.
- [ ] Secure API endpoint URL in `.env` for Flutter.
