# Architecture

# Overview

CaisseDZ follows a traditional MVC-inspired layered architecture adapted for Flutter Desktop.

The architecture is designed to be simple, modular, maintainable and easy to extend.

Each business module follows the same development pattern to keep the project consistent.

The data flow is intentionally straightforward:

UI → Service → SQLite → UI Refresh

Widgets never communicate directly with the database.

---

# Global Architecture

```
┌───────────────────────────────────────────────┐
│                User Interface                 │
│                (Screens)                      │
└───────────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────┐
│                 Dialogs                       │
│      Add / Edit / Delete / Details            │
└───────────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────┐
│                 Services                      │
│     Business Logic & Database Operations      │
└───────────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────┐
│                 SQLite                        │
│          DBCreate & Local Database            │
└───────────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────┐
│               Refresh UI                      │
└───────────────────────────────────────────────┘
```

---

# Typical Workflow

Example: Creating a Product

```
Product Screen

↓

Click "Add Product"

↓

Open Add Product Dialog

↓

Validate User Inputs

↓

ProductService.addProduct()

↓

SQLite INSERT

↓

Reload Product List

↓

Refresh DataGrid

↓

Update Dashboard Statistics
```

Every CRUD operation should follow this workflow.

---

# Layers

## Screens

Location

lib/screens/

Responsibilities

- Display user interface
- Receive user interactions
- Display DataGrid
- Open dialogs
- Call Services
- Refresh UI

Screens must never:

- Write SQL
- Execute database queries
- Contain business logic

---

## Dialogs

Location

lib/core/dialog/

Responsibilities

- Add data
- Edit data
- Delete confirmation
- Validation
- Details preview

Dialogs should remain lightweight.

Business logic belongs inside Services.

---

## Services

Location

lib/services/

Responsibilities

- Business logic
- CRUD operations
- Database access
- Validation
- Calculations
- Communication between modules

Services are the only layer allowed to communicate directly with SQLite.

Whenever possible, reuse existing services instead of creating duplicates.

---

## Models

Location

lib/data/models/

Responsibilities

Models represent application data only.

Every model should contain:

- Constructor
- fromMap()
- toMap()
- copyWith() (when appropriate)

Business logic should not be placed inside Models.

---

## Core

Location

lib/core/

Purpose

Shared components used by every module.

Contains:

- Dialogs
- Themes
- Shared Widgets
- DataGrid helpers
- Utilities
- Authentication helpers

Everything inside Core should be reusable.

---

## Localization

Location

lib/l10n/

Responsibilities

- Multi-language support
- Translation management

Never hardcode user-visible text.

Every new text must support localization.

---

## Router

Location

router.dart

Responsibilities

- Register application routes
- Navigate between Screens

Always register every new Screen inside router.dart.

Avoid creating custom navigation systems.

---

## Database

DBCreate.dart is responsible for:

- Database creation
- Table creation
- Database upgrades
- Initial data

All schema modifications must be centralized here.

---

# Dependency Rules

Allowed

Screen

↓

Service

↓

SQLite

Forbidden

Screen

↓

SQLite

Forbidden

Widget

↓

SQLite

Forbidden

Dialog

↓

SQLite

---

# Creating a New Module

Every new business module should follow these steps.

1. Create Model

↓

2. Add database table inside DBCreate.dart

↓

3. Create Service

↓

4. Create DataGrid Source

↓

5. Create Screen

↓

6. Create Dialogs

↓

7. Register Route

↓

8. Add Sidebar Menu

↓

9. Test CRUD

↓

10. Update Dashboard if required

---

# Service Communication

Services may communicate with other Services when necessary.

Examples

ProductService

↓

StockService

↓

MovementService

This helps keep business rules centralized.

Avoid circular dependencies.

---

# UI Components

Every Screen should reuse existing Core Widgets whenever possible.

Preferred components:

- Existing Buttons
- Existing Cards
- Existing Dialogs
- Existing Tables
- Existing Form Fields

Avoid creating duplicate UI components.

---

# DataGrid Standard

The project uses Syncfusion DataGrid.

Every module should follow the same table structure.

Reuse:

- Existing DataSource
- Existing Search
- Existing Filters

Avoid introducing different table systems.

---

# Architecture Principles

The architecture follows these principles.

## Simplicity

Prefer simple solutions.

---

## Reusability

Never duplicate existing code.

---

## Consistency

Every module should look and behave similarly.

---

## Separation of Responsibilities

UI handles presentation.

Services handle business logic.

SQLite handles persistence.

---

## Scalability

New modules should integrate naturally without changing the architecture.

---

# Forbidden Practices

Never:

- Write SQL inside Screens
- Write SQL inside Widgets
- Duplicate Services
- Duplicate Dialogs
- Duplicate Widgets
- Create another navigation system
- Ignore localization
- Bypass Services
- Break existing architecture

---

# AI Instructions

When implementing new features:

1. Analyze existing modules first.

2. Reuse existing architecture.

3. Search for reusable widgets before creating new ones.

4. Search for reusable dialogs.

5. Search for existing Services.

6. Follow the same CRUD workflow.

7. Preserve coding style.

8. Keep every module consistent with the rest of the project.

Claude should always behave as if it were extending an existing enterprise application rather than creating a new project.