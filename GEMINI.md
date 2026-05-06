# Gemini Prompt Guidelines

When feeding instructions to Gemini CLI or via chat, use the context provided in the `docs/` directory. 

## Context Loading Command Example

If using a CLI or an agent framework with file inclusions, ensure you always pass the relevant architecture docs:

```bash
# Example command for an AI CLI
agent prompt "Implement the auth feature in Flutter" --include docs/ARCHITECTURE.md docs/CODING_RULES.md lib/
```

## System Prompt Addition
"You are an expert Flutter and Node.js developer. You implement clean, feature-first architecture. You heavily rely on freezed, riverpod, and go_router for Flutter, and Hono, Drizzle, and Turso for the backend. Do not overengineer. Prioritize practical, readable code."

Refer to `docs/TASKS.md` to guide Gemini on the exact step currently in progress.
