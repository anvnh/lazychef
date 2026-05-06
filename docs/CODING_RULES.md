# Coding Rules & Best Practices

## General
- Write self-documenting code. Avoid redundant comments; comment the "why", not the "what".
- Use descriptive variable and function names.

## Flutter / Dart
- **State Management**: Use `Riverpod`. Avoid StatefulWidgets unless dealing with highly localized UI state (like text controllers or animations).
- **Immutability**: Use `freezed` for all data models and complex states.
- **Routing**: Use `go_router`. Pass data between routes via IDs (e.g., `/scan/:id`) rather than passing heavy objects directly when possible.
- **Network**: Use `Dio`. Always wrap network calls in `try-catch` blocks and return typed Result/Either classes or throw custom domain exceptions.
- **File Structure**: strictly adhere to the feature-first approach defined in the architecture document.
- **Widget Trees**: Keep `build` methods clean. Extract complex widget sub-trees into independent StatelessWidgets.

## Node.js / Hono
- **Type Safety**: Strictly type all API request bodies and responses using TypeScript interfaces or Drizzle inferred types.
- **Database Access**: All Turso interactions must happen through Drizzle ORM. No raw SQL strings unless completely unavoidable.
- **Error Handling**: Use a central error-handling middleware. Do not leak stack traces or raw database errors to the frontend.
- **Security**: 
  - Never store plaintext passwords. Use bcrypt or argon2.
  - Keep JWT secrets safe in environment variables.
  - Do not trust frontend input. Validate all incoming payload data.

## Integration
- **REST Principles**: Follow RESTful naming conventions for endpoints (`GET /api/scans`, `POST /api/scans`).
- **Data Transfer**: Use JSON. For file uploads, use `multipart/form-data`.
- **Stateless Backend**: The Node.js server must be stateless. All session data is stored in the JWT.
