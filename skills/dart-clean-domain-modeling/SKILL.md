---
name: dart-clean-domain-modeling
description: Design pure domain entities and business logic using Domain-Driven Design, "Tell Don't Ask", and fpdart Option. Use when creating domain entities, encapsulating business rules, eliminating raw nullability with Option, or modeling domain failures with Either.
---

# Clean Domain Modeling: DDD, Tell Don't Ask & Option Safety

Design pure, testable, framework-agnostic domain models in Dart by enforcing domain isolation, the "Tell Don't Ask" principle, and explicit null safety with `Option<T>`.

---

## 🏛️ Pure Domain Layer Isolation

The domain layer contains your core business rules and **MUST** remain independent of UI and platform frameworks:

- **ALLOWED:** Pure Dart (`dart:async`, `dart:math`), `package:fpdart`, `package:freezed_annotation`, `package:equatable`.
- **FORBIDDEN:** `package:flutter/*`, `dart:ui`, external UI formatting packages (`intl`, `timeago`).
- **Formatting & UI logic:** Put date/currency formatting into presentation layer extensions (e.g., `user_entity_ui_extensions.dart`), not the domain entity.

---

## 🗣️ "Tell Don't Ask" Principle

Do not query an entity's internal fields to make business decisions externally. **Tell the entity to evaluate its own state.**

```dart
// ❌ WRONG: "Asking" - Querying raw entity fields to make external decisions
List<QuestionEntity> getVisibleQuestions(
  List<QuestionEntity> questions,
  Map<String, AnswerEntity> answers,
) {
  final visible = <QuestionEntity>[];
  for (final q in questions) {
    if (q.parentQuestionId == null) {
      visible.add(q);
    } else {
      final parentAnswer = answers[q.parentQuestionId];
      if (parentAnswer?.value == q.requiredParentValue) {
        visible.add(q);
      }
    }
  }
  return visible;
}

// ✅ CORRECT: "Telling" - The entity encapsulates its own visibility logic
class QuestionEntity {
  const QuestionEntity({
    required this.id,
    required this.title,
    required this.parentQuestionId,
    required this.requiredParentValue,
  });

  final String id;
  final String title;
  final Option<String> parentQuestionId;
  final Option<String> requiredParentValue;

  bool isVisible(Map<String, AnswerEntity> answers) {
    return parentQuestionId.fold(
      () => true, // Root question is always visible
      (parentId) {
        final parentAnswer = answers[parentId];
        if (parentAnswer == null) return false;
        return requiredParentValue.fold(
          () => false,
          (expected) => parentAnswer.value == expected,
        );
      },
    );
  }
}

// Clean caller code delegating directly to the entity
List<QuestionEntity> getVisibleQuestions(
  List<QuestionEntity> questions,
  Map<String, AnswerEntity> answers,
) => questions.where((q) => q.isVisible(answers)).toList();
```

---

## 🛡️ Explicit Null Safety with `Option<T>` (`fpdart`)

Eliminate ambiguous `null` checks in domain entities by using `Option<T>`.

### The Rules:
1. Every domain entity field is marked `required`.
2. Fields that may be absent are wrapped in `required Option<T>`.
3. The `Option` wrapper itself is never null; it is always either `some(value)` or `none()`.

```dart
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required Option<String> middleName,  // Explicitly optional
    required Option<String> phoneNumber, // Explicitly optional
    required DateTime createdAt,
    required Option<DateTime> updatedAt,
  }) = _UserEntity;

  const UserEntity._();

  /// Business logic method inside entity
  String get displayName => middleName.fold(
    () => '$firstName $lastName',
    (middle) => '$firstName $middle $lastName',
  );

  bool get hasPhone => phoneNumber.isSome();
}

// Instantiation:
final user = UserEntity(
  id: 'usr_101',
  email: 'alex@example.com',
  firstName: 'Alex',
  lastName: 'Rivers',
  middleName: none(),
  phoneNumber: some('+1234567890'),
  createdAt: DateTime.now(),
  updatedAt: none(),
);
```

---

## ⚙️ Domain Services for Multi-Entity Orchestration

When a business rule spans multiple entities or cross-cutting calculations, extract a **Domain Service**:

```dart
class InsuranceEligibilityService {
  const InsuranceEligibilityService();

  bool isEligible({
    required UserEntity user,
    required List<QuestionEntity> answeredQuestions,
    required Map<String, AnswerEntity> answers,
  }) {
    if (!user.hasPhone) return false;
    final allAnswered = answeredQuestions.every((q) => q.isVisible(answers));
    return allAnswered;
  }
}
```

---

## 🛑 Functional Error Handling with `Either<Failure, T>`

Model domain operations using pure, typed failures:

```dart
// domain/failures/failure.dart
abstract class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// domain/repositories/order_repository.dart
abstract interface class OrderRepository {
  Future<Either<Failure, OrderEntity>> placeOrder(OrderParams params);
}
```
