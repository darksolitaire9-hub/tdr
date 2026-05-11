# Setup script for Windows (PowerShell / Nushell compatible)
# Run ONCE after cloning to scaffold the Flutter project shell.
#
# Prerequisites:
#   - Flutter SDK in PATH  (https://docs.flutter.dev/get-started/install/windows)
#   - Dart 3.3+  (bundled with Flutter)
#
# Usage (PowerShell):   .\setup.ps1
# Usage (Nushell):      ^powershell -File setup.ps1

Write-Host ">>> Scaffolding Flutter project (android/, ios/, etc.)..." -ForegroundColor Cyan

# Creates platform directories. Our existing lib/ files are NOT overwritten
# because flutter create skips files that already exist.
flutter create . --org com.example.todo --project-name todo_app --platforms android

Write-Host ">>> Installing dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host ">>> Running code generation (Drift, Riverpod, Freezed)..." -ForegroundColor Cyan
dart run build_runner build --delete-conflicting-outputs

Write-Host ">>> Running tests..." -ForegroundColor Cyan
flutter test

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "  Run app:       flutter run -d <device-id>" -ForegroundColor White
Write-Host "  List devices:  flutter devices" -ForegroundColor White
Write-Host "  Build APK:     flutter build apk --release" -ForegroundColor White
