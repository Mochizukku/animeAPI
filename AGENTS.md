# Agent Instructions

## Tech Stack
- **Framework:** Flutter (Dart)
- **Structure:** Standard Flutter layout (`lib/`, `test/`, `assets/`)

## Efficiency & Code Rules
- **Token Efficiency:** Keep diffs minimal. Edit only target files; do not rewrite unchanged logic, add extra comments, or auto-format unrelated code.
- **Strict Adherence:** Implement ONLY what is requested. Do NOT add unrequested UI elements, custom icons, emojis, or speculative decorative assets.
- **Dependencies:** Use existing packages in `pubspec.yaml`. Do not add new dependencies without explicit permission.
- **Dart Style:** Keep widgets small and modular. Prefer `const` constructors where possible.

## State & UI Rules
- **State Handling:** Use built-in `setState` or `ValueNotifier` for local widget state. Keep state logic close to the consuming widget without adding heavy third-party state managers (Bloc, Riverpod, etc.).
- **Separation:** Keep business/data logic in plain Dart classes outside the widget tree when possible.

## Commands
- **Install Deps:** `flutter pub get`
- **Run Tests:** `flutter test`
- **Environment Check:** `flutter doctor`