# Flutter Clean Skills 🚀

A curated suite of enterprise-grade, project-agnostic **Flutter & Dart Agent Skills** designed for **OpenCode**, **Claude Code**, and modern AI coding assistants.

These skills replace thousands of tokens of bloated cursorrules / prompt system instructions with lean, on-demand architectural workflows and strict guidelines.

---

## 📦 What's Included

| Skill | Description | Primary Concepts |
| :--- | :--- | :--- |
| **`flutter-clean-architecture`** | Feature-First Clean Architecture with BLoC & pragmatic CQRS | Unidirectional data flow, CQRS pass-through pragmatism, repository and Cubit isolation, Read/Write Cubit scoping, subscription cleanup in `close()`, and `BlocSelector`. |
| **`flutter-use-injectable`** | Compile-time Dependency Injection via `injectable` & `get_it` | Strictly annotation-driven DI, `@LazySingleton(as: Interface)`, `@lazySingleton` use cases, `@injectable` screen-scoped cubits, `@module` external packages, Dart 3 `abstract interface class`. |
| **`flutter-use-freezed`** | Freezed 3+ immutable data modeling & sealed state unions | Sealed class unions, abstract data classes, **exhaustive Dart 3 switch expressions** (eliminating `.when()` / `.map()`), DTO ↔ Entity mappers, `@JsonKey(includeToJson: false)`. |
| **`dart-clean-domain-modeling`** | Domain-Driven Design, "Tell Don't Ask", and fpdart Option | Zero Flutter/UI dependencies in domain, "Tell Don't Ask" business encapsulation, **strict null safety with `required Option<T>`**, pure domain services, `Either<Failure, T>`. |
| **`flutter-widget-best-practices`** | UI performance, context safety, and widget hygiene | **Context value caching** at top of `build()`, mandatory `if (!context.mounted) return;` after `await`, private widget classes over helper methods, Material 3 `colorScheme`, structured logging. |

---

## ⚡ Why Use Skills Over Monolithic Prompt Files?

- **Massive Context Savings:** Legacy prompt rule files (`global_ruleset.md`, `project_specific.md`) typically eat **5,000–8,000 tokens on every prompt turn**.
- **Sharp Attention:** In OpenCode and Claude Code, only brief descriptions (~250 tokens total) sit in the manifest. The complete skill (~500–800 tokens) is dynamically injected into context **only when relevant**.
- **Project Agnostic:** Works across any Flutter and Dart application using standard packages (`flutter_bloc`, `injectable`, `freezed`, `fpdart`).

---

## 🚀 Installation

### Option 1: Automatic Script (Windows PowerShell)

```powershell
.\install.ps1
```

Or target a specific environment:
```powershell
.\install.ps1 -Target opencode   # Installs to ~/.config/opencode/skills/
.\install.ps1 -Target claude     # Installs to ~/.claude/skills/
.\install.ps1 -Target agents     # Installs to ~/.agents/skills/
```

### Option 2: Automatic Script (macOS / Linux)

```bash
chmod +x install.sh
./install.sh
```

### Option 3: Manual Installation

Copy the skill directories from `skills/` to your agent tools directory:

- **OpenCode:** `~/.config/opencode/skills/`
- **Agents Standard:** `~/.agents/skills/`
- **Claude Code:** `~/.claude/skills/` or `<project-root>/.claude/skills/`

---

## 💡 How It Works

Once installed, your AI agent autonomously detects when to trigger each skill based on your prompts:

- *"Scaffold the authentication feature using clean architecture"* ➔ Invokes `@flutter-clean-architecture`
- *"Register the user repository and order usecase in DI"* ➔ Invokes `@flutter-use-injectable`
- *"Create the state union and DTOs for notifications"* ➔ Invokes `@flutter-use-freezed`
- *"Model the insurance policy domain entity and rules"* ➔ Invokes `@dart-clean-domain-modeling`
- *"Refactor this product details screen for performance"* ➔ Invokes `@flutter-widget-best-practices`

You can also explicitly trigger any skill in your prompt by typing `@skill-name`.

---

## 📄 License

MIT License. Feel free to use, modify, and distribute in your own projects.
