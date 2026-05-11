# Software Design Document — Flutter Todo App

**Version:** 1.0  
**Date:** 2026-05-11  
**Platform:** Android (Flutter 3.24, Dart 3.3)

---

## 1. Purpose & Scope

Single-platform Android todo app. Local-first: all data persists in SQLite on the device.
No backend required. Designed for correctness, performance, and future extensibility.

---

## 2. Architecture

### 2.1 Pattern: Clean Architecture + DDD

Three independent layers. Dependencies point inward.

```
┌────────────────────────────────────────────┐
│  Presentation                              │
│  Flutter UI · Riverpod providers           │
│  (depends on Domain only)                  │
├────────────────────────────────────────────┤
│  Domain  (pure Dart, zero Flutter deps)    │
│  Models · Repository Interfaces            │
├────────────────────────────────────────────┤
│  Data                                      │
│  Drift/SQLite · Repository Implementations │
│  (depends on Domain interfaces)            │
└────────────────────────────────────────────┘
```

### 2.2 DDD Mapping

| DDD Concept | Implementation |
|------------|----------------|
| Bounded Context | Todo Management |
| Aggregate Root | `Todo` (freezed, immutable) |
| Value Objects | `TodoPriority` enum, `TodoFilter` enum |
| Repository (Port) | `ITodoRepository` abstract interface |
| Repository (Adapter) | `TodoRepositoryImpl` (Drift-backed) |
| Application Service | `TodoActions` Riverpod notifier |

---

## 3. Data Model

### 3.1 Domain Model (`Todo`)

```dart
Todo {
  id:          String     // UUID v4
  title:       String     // 1–500 chars, trimmed
  description: String     // optional, trimmed, default ''
  isCompleted: bool       // default false
  priority:    enum       // low | medium | high, default medium
  createdAt:   DateTime
  completedAt: DateTime?  // set when isCompleted → true
}
```

### 3.2 Database Schema — `todos` table (Drift / SQLite)

| Column | Type | Constraint |
|--------|------|-----------|
| `id` | TEXT | PRIMARY KEY |
| `title` | TEXT | length 1–500 |
| `description` | TEXT | DEFAULT '' |
| `is_completed` | BOOLEAN | DEFAULT false |
| `priority` | TEXT | DEFAULT 'medium' (enum name) |
| `created_at` | INTEGER (Unix ms) | NOT NULL |
| `completed_at` | INTEGER (Unix ms) | NULLABLE |

**Schema version:** 1. Future changes use `MigrationStrategy` in `AppDatabase`.

### 3.3 Data Class vs Domain Model

Drift generates `TodoData` (persistence model). `TodoRepositoryImpl` maps it to/from `Todo` (domain model). The two are intentionally separate — domain logic never depends on Drift.

---

## 4. State Management

### 4.1 Provider Graph

```
ProviderScope
  sharedPreferencesProvider (keepAlive) ← overridden in main()
  appThemeModeProvider (keepAlive)       ← reads SharedPrefs
  appDatabaseProvider (keepAlive)        ← AppDatabase singleton
  todoRepositoryProvider (keepAlive)     ← ITodoRepository impl
  todoStreamProvider(filter, search)     ← Stream<List<Todo>>
  todoActionsProvider                    ← write-only notifier
```

### 4.2 Write vs Read Pattern

**Read:** `todoStreamProvider` returns a Drift stream. UI rebuilds automatically on any DB change. No polling.

**Write:** `todoActionsProvider.notifier.create/update/delete/toggle(...)`. Methods call the repository; Drift's stream emits the updated list.

---

## 5. Navigation

| Route | Widget | Purpose |
|-------|--------|---------|
| `/` | `HomePage` | List + filter + search |
| `/todo/new` | `TodoFormPage()` | Create |
| `/todo/edit/:id` | `TodoFormPage(todoId: id)` | Edit / delete |

Router: `go_router` declarative. Typed path parameters. No navigator stack manipulation.

---

## 6. Design System

### 6.1 Tokens

| Token | Value | Rationale |
|-------|-------|-----------|
| Primary seed | `#6366F1` (Indigo 500) | Calm, focused energy |
| Priority Low | `#10B981` | Green = safe/low urgency |
| Priority Medium | `#F59E0B` | Amber = attention |
| Priority High | `#EF4444` | Red = urgent |
| Font | Nunito | Rounded, friendly, legible |
| Card radius | 12px | Modern M3 feel |
| Card elevation | 0 | Flat with `outlineVariant` border |

### 6.2 Theme

Material 3 `ColorScheme.fromSeed()` generates the full palette from the primary seed.
Light and dark variants via `AppTheme.light()` / `AppTheme.dark()`.
Theme mode persisted to `SharedPreferences`.

### 6.3 Component Hierarchy (Atomic Design)

```
Atoms:    _PriorityDot, FilterChip (M3 built-in), Checkbox
Molecules: TodoTile (dot + checkbox + text), FilterBar
Organisms: HomePage (AppBar + FilterBar + List + FAB)
Pages:    HomePage, TodoFormPage
```

---

## 7. Performance

| Concern | Approach |
|---------|----------|
| List rendering | `ListView.builder` — lazy, O(visible) |
| DB reactivity | Drift streams — only changed queries re-emit |
| Animations | `flutter_animate` GPU-accelerated (`fadeIn`, `slideX`) |
| State granularity | `todoStreamProvider` is parameterized; filter changes re-subscribe |
| Singleton providers | `keepAlive: true` on DB and repository — no re-creation |
| `const` widgets | Used on all stateless leaf widgets |

---

## 8. Security

| Risk | Mitigation |
|------|-----------|
| SQL injection | Drift parameterized queries — no raw SQL |
| Input overflow | `withLength` on DB column + `maxLength` on form fields |
| Excessive input | Title ≤ 500 chars, description ≤ 1 000 chars; trimmed before save |
| Data exposure | Local-only, no network; SQLite file in app-private storage |
| No secrets | App contains no API keys, tokens, or credentials |
| Future network | Must add HTTPS, certificate pinning, OAuth 2.0 before any API calls |

---

## 9. Testing Strategy

| Layer | Kind | Tool | Target |
|-------|------|------|--------|
| Domain models | Unit | `flutter_test` | 100% |
| Repository | Unit (mock DB) | `mocktail` | 90% |
| Providers | Unit (`ProviderContainer`) | `flutter_riverpod/testing` | 80% |
| Widgets | Widget | `flutter_test` | Critical paths |
| DB integration | In-memory Drift | `NativeDatabase.memory()` | CRUD flows |

---

## 10. CI/CD Pipeline

```
push/PR to main or develop
  └─► quality job
        ├─ flutter pub get
        ├─ dart run build_runner build
        ├─ dart format --set-exit-if-changed
        ├─ flutter analyze
        └─ flutter test --coverage
              └─► codecov upload

  push to main or develop (not PRs)
  └─► build-apk job (needs: quality)
        └─ flutter build apk --release
              └─► artifact uploaded, retained 14 days
```

Concurrency group cancels in-flight runs for the same branch.

---

## 11. Extension Points

| Feature | What to add |
|---------|------------|
| Due dates | Drift migration v2: `DateTimeColumn? dueAt` in `Todos` |
| Categories | New `Tags` table + `TodoTags` join table; update `ITodoRepository` |
| Notifications | `flutter_local_notifications`, schedule on `dueAt` |
| Cloud sync | Swap `TodoRepositoryImpl` for a sync-aware adapter; domain unchanged |
| DB encryption | `sqlcipher_flutter_libs` + drift encryption plugin |
| App icon | `flutter_launcher_icons` package |
| Offline indicator | Wrap `appDatabaseProvider` errors; show banner |

---

## 12. File Ownership (by layer)

| Directory | Layer | Change frequency |
|-----------|-------|-----------------|
| `lib/domain/` | Domain | Rare — core business rules |
| `lib/data/` | Data | Medium — DB schema changes |
| `lib/presentation/providers/` | Application | Medium — new use cases |
| `lib/presentation/pages/` | UI | Frequent — UX iterations |
| `lib/core/theme/` | Cross-cutting | Rare — design system |
| `test/` | All | Grows with features |
