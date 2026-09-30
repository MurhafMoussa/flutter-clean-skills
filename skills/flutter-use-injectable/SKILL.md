---
name: flutter-use-injectable
description: Configure and manage dependency injection using injectable and get_it. Use when registering repositories, use cases, BLoCs/Cubits, external modules, setting up injection environments, or running build_runner.
---

# Dependency Injection with Injectable & GetIt

Manage dependency injection predictably in Flutter using compile-time code generation via `package:injectable` and `package:get_it`.

---

## 🛑 Golden Rule: Annotations Only

- **ALWAYS** use `@injectable`, `@lazySingleton`, or `@module` annotations.
- **NEVER** manually call `GetIt.instance.registerFactory` or `GetIt.instance.registerSingleton` in application code.
- **ALWAYS** re-run `build_runner` after modifying dependencies or constructors.

---

## 🏷️ Annotation Lifecycle Matrix

| Layer / Component | Annotation | Rationale |
| :--- | :--- | :--- |
| **Repository Implementation** | `@LazySingleton(as: Interface)` | Lazily instantiated singleton bound to its abstract interface contract |
| **Data Source (Remote/Local)** | `@LazySingleton(as: Interface)` | Stateless data-fetching service |
| **Domain Use Case** | `@lazySingleton` | Pure, stateless business logic service |
| **Cubit / BLoC** | `@injectable` | Factory lifecycle: fresh instance per widget tree / screen route |
| **External Service (Dio, Hive)** | `@module` + `@lazySingleton` | Wraps third-party classes that cannot be directly annotated |
| **Eager Service** | `@singleton` | Eagerly created on app startup (use sparingly) |

---

## 📝 Code Examples

### 1. Repository Interface & Implementation (Dart 3+)

```dart
// domain/repositories/user_repository.dart
abstract interface class UserRepository {
  Future<Either<Failure, UserEntity>> getUser(String id);
}

// data/repositories/user_repository_impl.dart
import 'package:injectable/injectable.dart';
import '../../domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource);
  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, UserEntity>> getUser(String id) async {
    // implementation...
  }
}
```

### 2. Domain Use Case

```dart
// domain/use_cases/get_user_usecase.dart
import 'package:injectable/injectable.dart';

@lazySingleton
class GetUserUseCase {
  GetUserUseCase(this._userRepository);
  final UserRepository _userRepository;

  Future<Either<Failure, UserEntity>> call(String id) =>
      _userRepository.getUser(id);
}
```

### 3. Cubit / BLoC (Factory Instance)

```dart
// presentation/cubits/user_profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._getUserUseCase) : super(const UserProfileState.initial());
  final GetUserUseCase _getUserUseCase;

  Future<void> load(String id) async {
    // implementation...
  }
}
```

### 4. External Dependencies via `@module`

```dart
// core/di/register_module.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
```

---

## ⚙️ Project Setup Checklist

### Step 1: Add Dependencies
```bash
flutter pub add get_it injectable
flutter pub add -d build_runner injectable_generator
```

### Step 2: Create Injection Entrypoint (`lib/core/di/injection.dart`)
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();
```

### Step 3: Initialize in `main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}
```

### Step 4: Run Code Generation
```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

---

## 🧪 Testing Overrides

In unit/widget tests, override dependencies cleanly without modifying production code:

```dart
setUp(() {
  getIt.reset();
  getIt.registerLazySingleton<UserRepository>(() => MockUserRepository());
});
```
