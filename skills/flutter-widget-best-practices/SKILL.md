---
name: flutter-widget-best-practices
description: Write performant, maintainable Flutter widgets following theme caching, context mounting safety, and widget extraction rules. Use when refactoring large build methods, handling theme colors and extensions, managing assets, or eliminating context bugs.
---

# Flutter Widget Best Practices & UI Hygiene

Enforce high-performance widget rendering, strict asynchronous context safety, and clean design token hygiene.

---

## ⚡ Context Value Caching (Performance)

Each `context.dependOnInheritedWidgetOfExactType` (e.g., `Theme.of(context)`, `context.colorScheme`, `MediaQuery.of(context)`) traverses the widget tree.

**Golden Rule:** At the start of the `build()` method, resolve and cache theme, colorScheme, text styles, and theme extensions into local variables.

```dart
// ✅ CORRECT - Single lookup cached at the start of build()
@override
Widget build(BuildContext context) {
  final colorScheme = context.colorScheme;
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;

  return Container(
    color: colorScheme.surface,
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Header', style: textTheme.titleLarge),
        Text('Subtitle', style: textTheme.bodyMedium),
      ],
    ),
  );
}

// ❌ WRONG - 5 separate widget-tree traversals inside a single build method
@override
Widget build(BuildContext context) {
  return Container(
    color: Theme.of(context).colorScheme.surface,      // Lookup 1
    child: Column(
      children: [
        Text('Header', style: Theme.of(context).textTheme.titleLarge), // Lookup 2
        Text('Subtitle', style: Theme.of(context).textTheme.bodyMedium), // Lookup 3
      ],
    ),
  );
}
```

---

## 🛡️ Asynchronous Context Safety (`context.mounted`)

Whenever an async operation occurs, the hosting widget might be unmounted before the Future resolves.

**Golden Rule:** Always check `if (!context.mounted) return;` after **EVERY** `await` before touching `context`.

```dart
// ✅ CORRECT - Safe context access after async boundary
Future<void> submitOrder(BuildContext context) async {
  final result = await context.read<OrderCubit>().submit();
  if (!context.mounted) return; // Critical guard!

  Navigator.of(context).pushNamed('/order-confirmation');
}

// ❌ WRONG - Unsafe context access (can crash if user popped screen during await)
Future<void> submitOrder(BuildContext context) async {
  await context.read<OrderCubit>().submit();
  Navigator.of(context).pushNamed('/order-confirmation'); // Crash: setState/context after dispose!
}
```

---

## 🧩 Private Widget Classes, NOT Helper Methods

**Golden Rule:** Extract reusable or complex sub-trees into private `StatelessWidget` / `StatefulWidget` classes (`_MySection`), **NEVER** into helper methods (`Widget _buildSection()`).

### Why?
1. **Rebuild Isolation:** Flutter skips rebuilding a `const StatelessWidget` when parent state changes. Helper functions rebuild unconditionally on every tick.
2. **Element Lifecycle:** Widgets have distinct `Element` identities; helper functions pollute the parent build method.
3. **Hot Reload & DevTools:** Dedicated classes appear cleanly in the Flutter Inspector.

```dart
// ✅ CORRECT - Private widget class with const constructor
class _UserSummarySection extends StatelessWidget {
  const _UserSummarySection({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Card(child: Text(user.name));
  }
}

// ❌ WRONG - Private build helper method
Widget _buildUserSummary(UserEntity user) {
  return Card(child: Text(user.name)); // Rebuilds on every parent build pass!
}
```

---

## 📐 Section Widgets & Screen Breakdown

- When a screen's `build()` method exceeds ~100 lines, break it into distinct section widgets (e.g. `_HeroSection`, `_DetailsCard`, `_ActionButtonBar`).
- Each widget should have a single, cohesive responsibility.

---

## 🎨 Theme Hygiene (Material 3)

1. **No Hardcoded Colors:**
   - **NEVER** use `Colors.blue`, `Colors.white`, or raw `Color(0xFF123456)`.
   - **ALWAYS** use `context.colorScheme.*` (`primary`, `onPrimary`, `surface`, `surfaceContainer`, `outline`, etc.).
2. **Do Not Override Theme Properties:**
   - If a widget's shape, elevation, padding, or borders are configured in `ThemeData` (e.g., `CardTheme`, `FilledButtonTheme`, `InputDecorationTheme`), **do not** manually override them inline unless explicitly required by design.

---

## 🖼️ Asset Management

- **NEVER** use raw string literals for assets (e.g. `'assets/images/logo.png'`).
- Use generated asset classes (`flutter_gen` / `spider`) or a centralized `AppAssets` class with `static const` strings.

---

## 📝 Logging Hygiene

- **NEVER** use `print()` or `debugPrint()` in production code.
- Use a dedicated structured logger (e.g. `logger`, `talker`).
- Always pass `error` and `stackTrace` in catch blocks.
