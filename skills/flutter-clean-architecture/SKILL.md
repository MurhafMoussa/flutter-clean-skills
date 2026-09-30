---
name: flutter-clean-architecture
description: Architect a Flutter feature using Clean Architecture, BLoC/Cubit, unidirectional data flow, and pragmatic CQRS. Use when structuring features, defining layer boundaries (domain, data, presentation), separating read/write operations, or coordinating BLoCs.
---

# Flutter Clean Architecture with BLoC & Pragmatic CQRS

Architect scalable, maintainable Flutter features with strict separation of concerns, unidirectional data flow, and pragmatic CQRS.

---

## 🧭 Unidirectional Data Flow

```text
Presentation (UI) ──▶ Cubit / BLoC ──▶ [UseCase]* ──▶ Repository ──▶ DataSource
       ▲                                                                   │
       └──────────────────────── Emitted State ◀───────────────────────────┘
```

---

## ⚡ Pragmatic CQRS Pattern

Avoid unnecessary pass-through boilerplate while strictly safeguarding business logic:

1. **Write Operations (Mutations - Create, Update, Delete):**
   - **MUST** go through a dedicated `UseCase`.
   - Business validations, multi-repository updates, side-effects, and mutations belong in use cases.
2. **Complex Read Operations:**
   - **MUST** go through a `UseCase` when combining data from multiple repositories, formatting across domains, or running business rules.
3. **Simple 1:1 Read Operations (Pass-throughs):**
   - `ReadCubit` **MAY** directly call a `Repository` IF AND ONLY IF there is zero business logic and it is a simple 1:1 data fetch.

```dart
// ✅ CORRECT - Write operation MUST use a UseCase
@injectable
class TodoWriteCubit extends Cubit<TodoWriteState> {
  TodoWriteCubit(this._createTodoUseCase) : super(const TodoWriteState.initial());
  final CreateTodoUseCase _createTodoUseCase;

  Future<void> createTodo(String title) async {
    emit(const TodoWriteState.loading());
    final result = await _createTodoUseCase(CreateTodoParams(title: title));
    result.fold(
      (failure) => emit(TodoWriteState.failure(failure)),
      (todo) => emit(TodoWriteState.success(todo)),
    );
  }
}

// ✅ CORRECT - Simple Read operation MAY bypass UseCase to prevent pass-through boilerplate
@injectable
class UserProfileReadCubit extends Cubit<UserProfileState> {
  UserProfileReadCubit(this._userRepository) : super(const UserProfileState.initial());
  final UserRepository _userRepository;

  Future<void> loadProfile() async {
    emit(const UserProfileState.loading());
    final result = await _userRepository.getProfile();
    result.fold(
      (failure) => emit(UserProfileState.failure(failure)),
      (profile) => emit(UserProfileState.success(profile)),
    );
  }
}

// ❌ WRONG - Never orchestrate multiple repos or business rules inside a Cubit
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._orderRepository, this._paymentRepository) : super(const CheckoutState.initial());
  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;

  Future<void> checkout() async {
    // ❌ Business orchestration belongs in CheckoutUseCase!
    await _paymentRepository.charge();
    await _orderRepository.createOrder();
  }
}
```

---

## 🛡️ Boundary Enforcement Rules

1. **Repositories MUST NOT call other Repositories:**
   - Repositories only communicate with data sources and return domain models.
   - When data from multiple domains is required, orchestrate them inside a **UseCase**.
2. **Cubits/BLoCs MUST NOT inject other Cubits/BLoCs:**
   - Injecting one Cubit into another causes tight coupling and circular dependency leaks.
   - Communicate between Cubits reactively using `BlocListener` or `MultiBlocListener` in the presentation layer.
3. **UseCases MUST NOT inject other UseCases:**
   - Each use case represents one self-contained business operation.
   - Orchestration across repositories happens within that single use case.

```dart
// ✅ CORRECT - Orchestrate multiple repositories inside a single UseCase
@lazySingleton
class CreateTodoWithUserInfoUseCase extends ResultFutureUseCase<TodoEntity, String> {
  CreateTodoWithUserInfoUseCase(this._todoRepository, this._userRepository);
  final TodoRepository _todoRepository;
  final UserRepository _userRepository;

  @override
  ResultFuture<TodoEntity> call(String title) async {
    final userResult = await _userRepository.getCurrentUser();
    return userResult.fold(
      (failure) => Left(failure),
      (user) => _todoRepository.createTodo(title: title, userId: user.id),
    );
  }
}

// ✅ CORRECT - Reactive Cubit communication via MultiBlocListener
MultiBlocListener(
  listeners: [
    BlocListener<TodoWriteCubit, TodoWriteState>(
      listenWhen: (previous, current) => current is TodoWriteSuccess,
      listener: (context, state) {
        context.read<TodoListReadCubit>().refresh();
      },
    ),
  ],
  child: const TodoScreenContent(),
)
```

---

## 📦 CQRS Scoping & Lifecycle Rules

Manage BLoC/Cubit lifecycles strictly to eliminate memory leaks and stale state:

| Cubit Type | Scope | Registration Site | Lifecycle |
| :--- | :--- | :--- | :--- |
| **Shared ReadCubit** | App-wide global state (Auth status, user preferences, theme, locale) | `app.dart` / root `MultiBlocProvider` | Kept alive for app lifecycle |
| **Feature ReadCubit** | Feature-specific read/caching state (Product list, search results, notifications) | Screen-level `BlocProvider` | Scoped to feature flow |
| **WriteCubit** | Mutation operations (Create, Update, Delete, Submit form) | Screen-level `BlocProvider` | **ALWAYS** disposed on route pop |

### Clean Subscriptions & Timers

Always cancel stream subscriptions and timers inside `close()`:

```dart
@injectable
class RealtimeFeedCubit extends Cubit<FeedState> {
  RealtimeFeedCubit(this._feedRepository) : super(const FeedState.initial());
  final FeedRepository _feedRepository;

  StreamSubscription<List<FeedItem>>? _feedSubscription;
  Timer? _pollingTimer;

  void startListening() {
    _feedSubscription?.cancel();
    _feedSubscription = _feedRepository.streamFeed().listen((items) {
      emit(FeedState.loaded(items));
    });
  }

  @override
  Future<void> close() {
    _feedSubscription?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
```

---

## ⚡ Granular UI Rebuilds with `BlocSelector`

Prefer `BlocSelector` over `BlocBuilder` to rebuild only when the relevant state slice changes:

```dart
// ✅ CORRECT - Granular rebuild: rebuilds ONLY when isAuthenticated changes
BlocSelector<AuthCubit, AuthState, bool>(
  selector: (state) => state.isAuthenticated,
  builder: (context, isAuthenticated) {
    return isAuthenticated ? const HomeScreen() : const LoginScreen();
  },
)

// ❌ WRONG - Rebuilds the entire tree when unrelated fields change (e.g., token, user profile)
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    return state.isAuthenticated ? const HomeScreen() : const LoginScreen();
  },
)
```

---

## 📁 Directory Structure (Feature-First)

Organize features into cohesive, self-contained slices:

```text
lib/features/feature_name/
├── domain/
│   ├── entities/                  # Pure Dart immutable entities
│   ├── repositories/              # abstract interface class contracts
│   └── use_cases/                 # Single-purpose business operations
├── data/
│   ├── data_sources/              # Remote API & local storage datasources
│   ├── dtos/                      # JSON-serializable DTOs / models
│   ├── mappers/                   # Extension mappers (Entity ↔ DTO)
│   └── repositories/              # Repository implementations
└── presentation/
    ├── cubits/                    # Feature Read & Write Cubits + States
    ├── pages/                     # Route-level screens
    └── widgets/                   # Focused section & private UI widgets
```

### Conventions:
- **One class per file**: Name files after classes in `snake_case` (e.g. `create_todo_usecase.dart`).
- **Relative imports within feature**: Use relative imports inside `lib/features/<feature>/...` to keep features modular.
- **Package imports across features**: Use `package:app_name/...` when referencing cross-feature contracts.
