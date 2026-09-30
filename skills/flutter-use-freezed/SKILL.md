---
name: flutter-use-freezed
description: Define immutable data classes, DTOs, domain models, params, and state unions using Freezed 3+. Use when creating value objects, data models with JSON serialization, sealed state unions, or refactoring away from legacy .when()/.map().
---

# Immutable Data Classes & State Unions with Freezed 3+

Generate boilerplate-free immutable data classes, DTOs, and type-safe state unions using `package:freezed`.

---

## ⚡ Core Rules

1. **State Unions:** Use `sealed class` with `@freezed` for union variants (e.g. `Initial`, `Loading`, `Success`, `Failure`).
2. **Data Classes:** Use `abstract class` with `@freezed` for single data models, DTOs, and params.
3. **Pattern Matching:** **ALWAYS** use Dart 3 `switch` expressions. **NEVER** call `.when()` or `.map()`.
4. **Const Constructors:** Declare `const factory` for all state and data variants.
5. **JSON Serialization:** Include `part '<file>.g.dart';` and `factory <Class>.fromJson(...) => _$<Class>FromJson(json);`.

---

## 🧩 State Unions (Sealed Classes)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required UserEntity user}) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.failure({required String message}) = _Failure;
}
```

### Pattern Matching with Switch Expressions (Dart 3+)

```dart
// ✅ CORRECT - Exhaustive, compiler-checked Dart 3 switch expression
final statusWidget = switch (state) {
  _Initial() => const Text('Welcome'),
  _Loading() => const CircularProgressIndicator(),
  _Authenticated(:final user) => UserCard(user: user),
  _Unauthenticated() => const LoginForm(),
  _Failure(:final message) => ErrorBanner(message: message),
};

// ❌ WRONG - Legacy Freezed when/map methods
state.when(
  initial: () => ...,
  loading: () => ...,
  authenticated: (user) => ...,
  unauthenticated: () => ...,
  failure: (msg) => ...,
);
```

---

## 📦 Data Classes & DTOs

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
abstract class UserDto with _$UserDto {
  const factory UserDto({
    @JsonKey(includeToJson: false) required String id,
    required String email,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}
```

---

## 🔄 Entity ↔ DTO Conversion Extensions

Keep serialization details in the data layer by using extension mappers:

```dart
// data/mappers/user_mapper.dart
extension UserDtoMapper on UserDto {
  UserEntity get toEntity => UserEntity(
    id: id,
    email: email,
    name: '$firstName $lastName',
    avatarUrl: avatarUrl,
  );
}

extension UserEntityMapper on UserEntity {
  UserDto toDto() => UserDto(
    id: id,
    email: email,
    firstName: name.split(' ').first,
    lastName: name.split(' ').skip(1).join(' '),
    avatarUrl: avatarUrl,
  );
}
```

---

## 🛠️ Code Generation Workflow

1. Add dependencies:
   ```bash
   flutter pub add freezed_annotation json_annotation
   flutter pub add -d build_runner freezed json_serializable
   ```
2. Run generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
