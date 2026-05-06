# AI Agent Instructions

Hello AI Coding Assistant! 

You are working on the "LazyChef" application, a platform consisting of a Flutter frontend and a Node.js/Hono backend. 

Your goal is to follow the architecture, coding rules, and implementation plan outlined in the `docs/` folder to build out the features of this project.

## How to use this workspace

1. Read `docs/ARCHITECTURE.md` to understand the system design, tech stack, and database schema.
2. Read `docs/CODING_RULES.md` to understand the code style and patterns you must enforce.
3. Check `docs/IMPLEMENTATION_PLAN.md` to see the macro-level phases of the project.
4. Use `docs/TASKS.md` to see the granular tasks. Update this file by checking off tasks as you complete them.

## Core Directives
- NEVER connect the Flutter app directly to the Turso database.
- The Flutter app only communicates with the Node.js backend via HTTPS using the Dio package.
- All secrets, API keys, and database connections must be securely managed in the backend.
