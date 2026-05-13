# Software Design Document — Moodboard Todo App

**Version:** 1.1  
**Date:** 2026-05-13  
**Platform:** Android (Flutter 3.24, Dart 3.3)

---

## 1. Purpose & Scope

Single-platform Android todo app. **Infinite Moodboard Canvas**: all data persists locally in SQLite. 
Unlike standard list-based apps, this is a spatial, tactile environment for thoughts and tasks.
Tasks are "stickers" on an infinite canvas, supporting free-form positioning and rotation.

---

## 2. Architecture

### 2.1 Pattern: Feature-First Architecture

The project follows a **Feature-first** organization. Code is grouped by high-level features (e.g., `todos`) to improve scalability and discoverability.

```
lib/
├── core/                   (Cross-cutting: Theme, Base DB, Global providers)
├── features/
│   └── todos/              (Feature: Todo Management)
│       ├── data/           (Repositories, Data sources)
│       ├── domain/         (Models, Interfaces)
│       └── presentation/   (Pages, Widgets, Providers)
├── router/                 (Navigation)
├── services/               (Global shared services: Audio, Hardware, NLP)
└── main.dart               (Entry point)
```

Dependencies point from Feature layers to Core/Domain layers.

### 2.2 Domain & Services

| Concept | Implementation |
|------------|----------------|
| Bounded Context | Todo Management |
| Aggregate Root | `Todo` (freezed, immutable) |
| Value Objects | `TodoPriority`, `TodoFilter`, `TodoRecurrence` |
| Application Service | `TodoActions` Riverpod notifier |
| Domain Service | `TaskParserService` (Natural Language Parsing) |
| Infrastructure Service | `HardwareService` (Volume buttons), `AudioService` |

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
  scheduledAt: DateTime?  // NLP-parsed date/time
  recurrence:  enum?      // daily | weekly
  // Spatial properties
  posX:        double     // Canvas X coordinate
  posY:        double     // Canvas Y coordinate
  rotation:    double     // Sticker rotation in radians
}
```

### 3.2 Database Schema — `todos` table (Drift / SQLite)

| Column | Type | Constraint |
|--------|------|-----------|
| `id` | TEXT | PRIMARY KEY |
| `title` | TEXT | length 1–500 |
| `description` | TEXT | DEFAULT '' |
| `is_completed` | BOOLEAN | DEFAULT false |
| `priority` | TEXT | DEFAULT 'medium' |
| `created_at` | INTEGER (Unix ms) | NOT NULL |
| `completed_at` | INTEGER (Unix ms) | NULLABLE |
| `scheduled_at` | INTEGER (Unix ms) | NULLABLE |
| `recurrence` | TEXT | NULLABLE |
| `pos_x` | REAL | DEFAULT 0.0 |
| `pos_y` | REAL | DEFAULT 0.0 |
| `rotation` | REAL | DEFAULT 0.0 |

**Schema version:** 3.

---

## 4. State Management & Navigation

### 4.1 Provider Graph

```
ProviderScope
  sharedPreferencesProvider (keepAlive)
  appDatabaseProvider (keepAlive)
  todoStreamProvider(filter)             ← Stream<List<Todo>>
  todoActionsProvider                    ← Write-only notifier (CRUD + Position)
  dailyFocusProvider                     ← Toggle for "Today" view
  hardwareServiceProvider                ← Volume button stream
  taskParserServiceProvider              ← NLP logic
  spatialGridProvider                    ← $O(1)$ collision mapping
  collisionDisplacementsProvider         ← Active kinetic push vectors
```

### 4.2 UI Flow (Canvas)

| View | Widget | Purpose |
|-------|--------|---------|
| **Kinetic Moodboard** | `InteractiveViewer` + `Stack` | Spatial canvas where stickers physically interact. |
| **Focus Mode** | `HomePage` (Filtered) | Shows only tasks scheduled for "Today" |

**Interaction Pattern:**
- **Kinetic Drag:** Dragging a sticker smoothly pushes neighboring stickers out of the way.
- **Sensory Redundancy:** Dragging triggers visual elevation, audio sliding, and haptic ticks.
- **Double Tap:** Toggle completion (strikethrough).
- **Long Press:** Delete sticker.
- **Hardware Up:** Open input focus + Play "Create" sound.

---

## 5. Design System

### 5.1 Tokens & UX

| Token | Value | Rationale |
|-------|-------|-----------|
| Stickers | Pink, Blue, Yellow, Green, Purple | High-contrast playful palette |
| Font (Short) | Space Grotesk (Bold) | Loud, punchy for brief thoughts |
| Font (Long) | Caveat | Personal, handwritten feel for notes |
| The Sensory Triad | Visual (Scale/Shadow) + Haptic (Impact) + Audio | Multisensory redundancy ensures interaction feels "real" and is accessible. |

### 5.2 Kinetic Typography & Animation

Stickers dynamically scale font size based on length. When a sticker is "pushed" by another, it utilizes an `AnimatedScale` (0.95x) to create a visual "squash" effect, providing immediate tactile feedback.

---

## 6. Performance & UX Optimization

| Concern | Approach |
|---------|----------|
| Canvas Performance | `InteractiveViewer` with `TransformationController`. Panning/Scaling locks during drag. |
| Collision Detection | **Spatial Hash Grid:** Reduces $O(N^2)$ collision checks to $O(k)$, maintaining 60 FPS for hundreds of stickers. |
| DB reactivity | Drift streams — only changed queries re-emit |
| State Granularity | `updatePosition` uses debounced or per-drop updates. Temporary displacements are handled entirely in memory (`dragOffsetProvider`). |

---

## 7. Security & Safety

- **Local-Only:** No network traffic; all data stays in the device's sandbox.
- **Input Sanitization:** NLP stripping ensures titles remain clean while extracting metadata.
- **Hardware Safety:** Uses specific button interception for accessible fast-input.

---

## 8. Testing Strategy

| Layer | Kind | Tool | Target |
|-------|------|------|--------|
| Domain models | Unit | `flutter_test` | 100% |
| Repository | Unit (mock DB) | `mocktail` | 90% |
| Providers | Unit (`ProviderContainer`) | `flutter_riverpod/testing` | 80% |
| Widgets | Widget | `flutter_test` | Critical paths (Moodboard rendering) |
| DB integration | In-memory Drift | `NativeDatabase.memory()` | CRUD + Spatial flows |

---

## 9. CI/CD Pipeline

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

## 10. Extension Points

| Feature | What to add |
|---------|------------|
| Categories | New `Tags` table + `TodoTags` join table; update `ITodoRepository` |
| Notifications | `flutter_local_notifications`, schedule on `scheduledAt` |
| Cloud sync | Swap `TodoRepositoryImpl` for a sync-aware adapter; domain unchanged |
| DB encryption | `sqlcipher_flutter_libs` + drift encryption plugin |
| App icon | `flutter_launcher_icons` package |
| Canvas Themes | Multiple canvas backgrounds (cork, paper, dark felt) |

---

## 11. File Ownership (by feature/layer)

| Directory | Layer | Change frequency |
|-----------|-------|-----------------|
| `lib/features/todos/domain/` | Domain | Rare — core business rules |
| `lib/features/todos/data/` | Data | Medium — DB schema changes |
| `lib/features/todos/presentation/` | UI/App | Frequent — UX iterations |
| `lib/core/` | Core | Rare — base infra |
| `lib/services/` | Shared | Medium — cross-cutting logic |
| `test/` | All | Grows with features |
