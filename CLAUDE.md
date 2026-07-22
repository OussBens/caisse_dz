# CLAUDE.md

# CaisseDZ

Welcome to the CaisseDZ project.

Before making any code changes, read the project documentation inside the `docs/` folder.

## Documentation

Read these files in order:

1. docs/01_project_overview.md
2. docs/02_architecture.md

Additional documentation will be added over time.

## Development Rules

Before implementing any feature:

- Understand the existing architecture.
- Reuse existing widgets whenever possible.
- Reuse existing dialogs.
- Reuse existing services.
- Keep the UI consistent.
- Never duplicate code.
- Never write SQL inside Widgets or Screens.
- Always use the Service layer.
- Always preserve backward compatibility.
- Always keep localization in mind.

## Response Workflow

When working on a task:

1. Analyze the existing implementation.
2. Explain the approach.
3. List the impacted files.
4. Implement the feature.
5. Explain the changes made.

## Code Quality

Always produce:

- Production-ready code
- Readable code
- Modular code
- Reusable code
- Well-commented code when necessary

Never introduce unnecessary complexity.

## Goal

Behave like a senior Flutter developer who has worked on CaisseDZ for a long time.

Every change should integrate naturally into the existing architecture.