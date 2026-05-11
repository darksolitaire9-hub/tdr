# Handoff: Flutter Todo App

**Status:** Foundation complete — needs `flutter create` scaffold + codegen run.  
**Updated:** 2026-05-11  
**Environment:** Windows 11, Zed editor, Nushell + PowerShell, ripgrep (`rg`) for search.

---

## Quick Context

Local-first Android todo app. All data in on-device SQLite — no backend, no network.  
Stack: Flutter 3.24 / Dart 3.3 · Material 3 · Riverpod · Drift · Freezed · go_router.

---

## Architecture

```
Presentation  ──reads/writes──►  Domain  ◄──implements──  Data
(Riverpod                        Models                    (Drift
 Pages/Widgets)                  + Interfaces              SQLite)
```

DDD concepts applied:

| Concept | File |
|---------|------|
| Aggregate Root | `lib/domain/models/todo.dart` — `Todo` (freezed) |
| Value Objects | `TodoPriority`, `TodoFilter` (enums) |
| Repository Port | `lib/domain/repositories/i_todo_repository.dart` |
| Repository Adapter | `lib/data/repositories/todo_repository_impl.dart` |
| Use Cases | Inline in `TodoActions` Riverpod notifier |

---

## File Map

```
F:\may\todo\
├── pubspec.yaml                              deps
├── analysis_options.yaml                     strict lints + riverpod_lint
├── setup.ps1                                 ONE-TIME first-run script
├── .github/workflows/ci.yml                  analyze → test → build APK
├── lib/
│   ├── main.dart                             ProviderScope + SharedPrefs init
│   ├── app.dart                              MaterialApp.router + theme watch
│   ├── router/app_router.dart                GoRouter: / /todo/new /todo/edit/:id
│   ├── core/
│   │   ├── theme/app_colors.dart             brand + priority color tokens
│   │   ├── theme/app_theme.dart              Material 3 light + dark themes
│   │   └── providers/theme_provider.dart     ThemeMode persisted to SharedPrefs
│   ├── domain/
│   │   ├── models/todo.dart                  Todo (freezed), TodoPriority, TodoFilter
│   │   └── repositories/i_todo_repository.dart  abstract interface
│   ├── data/
│   │   ├── local/app_database.dart           Drift DB, Todos table, CRUD + streams
│   │   └── repositories/todo_repository_impl.dart  domain ↔ drift mapping
│   └── presentation/
│       ├── providers/database_provider.dart  appDatabase + todoRepository (keepAlive)
│       ├── providers/todo_provider.dart      todoStream (StreamProvider) + TodoActions
│       ├── pages/home_page.dart              list + filter chips + search + FAB
│       ├── pages/todo_form_page.dart         create / edit / delete form
│       └── widgets/
│           ├── todo_tile.dart                swipe-delete, priority dot, animations
│           ├── filter_bar.dart               All/Active/Done FilterChips
│           └── empty_state.dart              contextual per-filter empty state
└── test/
    ├── domain/todo_test.dart                 Todo model: defaults, copyWith, equality
    └── data/todo_repository_test.dart        repository: filter mapping, toggle, create
```

---

## State Flow

```
User taps checkbox
  → TodoTile calls todoActionsProvider.notifier.toggle(id)
  → TodoRepositoryImpl.toggleCompletion(id)
  → AppDatabase.toggleTodo(id, completed: true)
  → SQLite UPDATE

SQLite UPDATE fires Drift stream
  → AppDatabase.watchTodos() emits new list
  → todoStreamProvider re-emits
  → ListView.builder rebuilds — ZERO manual refresh needed
```

---

## What's Done

- [x] Design tokens + Material 3 light/dark theme (Nunito font)
- [x] Domain layer: `Todo`, `TodoPriority`, `TodoFilter`, `ITodoRepository`
- [x] Drift database: schema v1, all CRUD + reactive streams
- [x] Repository impl: filter mapping, UUID gen, input trim, domain↔data conversion
- [x] Riverpod providers: DB singleton, repo, stream, write actions, theme
- [x] Home page: list, filter bar, search, theme toggle, FAB
- [x] Form page: create + edit + confirm-delete dialog, priority segmented button
- [x] Todo tile: swipe-to-delete (flutter_slidable), priority dot, animations
- [x] GitHub Actions CI: format → analyze → test+coverage → build APK
- [x] Unit tests: domain model + repository (mocktail)

## What's Next

- [ ] **FIRST**: run `.\setup.ps1` (scaffolds android/, runs codegen, runs tests)
- [ ] Widget tests for `HomePage` and `TodoFormPage` with `ProviderScope`
- [ ] Integration tests using Drift in-memory `NativeDatabase.memory()`
- [ ] Due dates: Drift schema v2 migration (`DateTimeColumn? dueAt`)
- [ ] Notifications: `flutter_local_notifications` for due-date reminders
- [ ] App icon + splash: `flutter_launcher_icons`, `flutter_native_splash`
- [ ] Release signing: `key.properties` + `build.gradle` signing config
- [ ] Categories/tags (future: new `Tags` table, many-to-many)

---

## Key Conventions

| Convention | Rule |
|-----------|------|
| Commits | Atomic — one logical change, Conventional Commits format |
| Private widgets | Prefix `_` (e.g. `_PriorityDot`) |
| Generated files | Gitignored — run `dart run build_runner build` after model changes |
| Drift data class | `TodoData` (not `Todo`) via `@DataClassName('TodoData')` |
| Domain model | `Todo` (freezed, pure Dart) — no Flutter/drift imports |
| Input sanitization | Always `.trim()` before storage; max lengths in DB + form validators |
| No `print()` | Use `debugPrint()` |
| Parameterized queries | Drift handles this — never raw SQL string interpolation |

---

## Commands (PowerShell / Nushell)

```powershell
# First-time setup
.\setup.ps1

# Daily dev
flutter run -d <device-id>
flutter devices                                          # list connected

# Code generation (after editing *.dart models)
dart run build_runner build --delete-conflicting-outputs

# Test
flutter test
flutter test --coverage

# Search codebase (ripgrep)
rg "todoRepository" lib/
rg "TodoFilter" --type dart

# Analyze
flutter analyze

# Format
dart format lib/ test/

# Build
flutter build apk --release
```

---

## Design Tokens Quick Reference

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#6366F1` | Seed for Material 3 color scheme |
| Priority Low | `#10B981` | Green dot on TodoTile |
| Priority Medium | `#F59E0B` | Amber dot on TodoTile |
| Priority High | `#EF4444` | Red dot on TodoTile |
| Font | Nunito (google_fonts) | All text |
| Card radius | 12px | Cards, inputs, containers |
| Elevation | 0 | Cards use `outlineVariant` border instead |

---

## Security Notes

- **No network** — pure local-first; no attack surface from external comms
- **SQLi** — Drift uses parameterized queries exclusively; no raw SQL
- **Input overflow** — DB column `withLength` + form `maxLength` validators
- **Secrets** — none; app has no API keys or credentials
- **File access** — SQLite file created by `driftDatabase()` in app-private storage
- **Future** — if network is added: add HTTPS + certificate pinning + OAuth 2.0

---

## Atomic Commit Guide

Use Conventional Commits. One logical unit per commit.

```
feat(db): add Todos drift table and CRUD methods
feat(domain): add Todo freezed model and ITodoRepository interface
feat(repo): implement TodoRepositoryImpl with filter mapping
feat(providers): add database, repository, and todo stream providers
feat(ui): add HomePage with filter bar and todo list
feat(ui): add TodoFormPage for create and edit
feat(ci): add GitHub Actions workflow for analyze, test, build APK
test(domain): add Todo model unit tests
test(repo): add TodoRepositoryImpl unit tests with mocktail
```
