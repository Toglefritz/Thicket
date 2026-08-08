---
title: Dart Coding Standards
description: Architecture conventions, strong typing, file organization, JSON handling, and unit testing practices for pure Dart (non-Flutter) projects.
tags:
  - dart
  - clean-code
  - coding-standards
---

# Dart Coding Standards

This document defines coding standards, style guidelines, and architecture conventions for pure Dart projects (command-line tools, backend services, server-side applications, and shared packages) without Flutter.

## Architecture Pattern: Separation of Concerns

Pure Dart applications must enforce a clean separation of concerns, separating business logic, network/database services, data models, and entry point interfaces (such as CLI entry points).

### Service / Repository Pattern
- Business logic and external API communication should reside in service or repository classes.
- Use constructor-based dependency injection to pass dependencies (e.g., API clients, database adapters) explicitly.
- Avoid global state or direct singleton calls within core business logic.

```dart
// Service handling business logic
class AuthenticationService {
  const AuthenticationService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResult> login(AuthCredentials credentials) async {
    final Map<String, dynamic> response = await _apiClient.post(
      '/auth/login',
      body: credentials.toJson(),
    );
    return AuthResult.fromJson(response);
  }
}
```

### Dependency Injection
- Pass all external service dependencies in the constructor.
- Program against abstract interfaces when mocking is required for testing.

```dart
// Prefer interface abstractions for mockability
abstract interface class ApiClient {
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body});
}
```

---

## Code Style & Type Safety

### Type Safety and Strong Typing
- All variables must be explicitly typed, including local variables within function bodies.
- Never rely on type inference with `var` or `dynamic` unless absolutely necessary.
- Use specific types rather than generic types when possible.
- Prefer nullable types (`String?`) over dynamic when null values are expected.

**✅ Preferred strong typing:**
```dart
void processApplications() {
  final List<Application> applications = getApplications();
  final Map<String, int> statusCounts = <String, int>{};
  final String defaultStatus = 'pending';
  
  for (final Application app in applications) {
    final String status = app.status ?? defaultStatus;
    final int currentCount = statusCounts[status] ?? 0;
    statusCounts[status] = currentCount + 1;
  }
}
```

**❌ Avoid type inference and dynamic:**
```dart
void processApplications() {
  var applications = getApplications(); // Type unclear
  var statusCounts = {}; // Dynamic map
  var defaultStatus = 'pending'; // Inferred as String, but be explicit
  
  for (var app in applications) { // Type unclear
    var status = app.status ?? defaultStatus;
    var currentCount = statusCounts[status] ?? 0;
    statusCounts[status] = currentCount + 1;
  }
}
```

### Strong Typing Guidelines
- Declare the full type for collections: `List<String>`, `Map<String, int>`, `Set<Application>`.
- Use explicit types for function parameters and return values.
- Type cast with `as` operator when necessary, but prefer strong typing to avoid casts.
- Use `late` keyword with explicit types for variables initialized after declaration.

### Linting & Formatting
- Follow standard linting rules (e.g., `very_good_analysis` or `lints/recommended`).
- Prefer single quotes for strings.
- Always declare return types (e.g., `void`, `Future<void>`, `int`).
- Use relative imports for local files.
- Avoid lines longer than 80 characters when practical.

### Documentation
- Document all public classes, methods, and functions.
- Use `///` for documentation comments.
- Include parameter descriptions and expected return types for complex methods.

### Error Handling
- Use specific exception types when possible (avoid catching generic `Exception` or `Object`).
- Handle async operations with try-catch blocks and ensure any resources (sockets, file descriptors, database connections) are closed properly in a `finally` block.

```dart
Future<void> writeLog(String message) async {
  final File file = File('app.log');
  final IOSink sink = file.openWrite(mode: FileMode.writeOnlyAppend);
  try {
    sink.writeln('${DateTime.now().toIso8601String()}: $message');
    await sink.flush();
  } catch (e) {
    print('Failed to write log: $e');
  } finally {
    await sink.close();
  }
}
```

---

## File Organization

### Naming Conventions
- Use snake_case for file names.
- Use PascalCase for class names and enum names.
- Use camelCase for variable and method names.

### Directory Structure
- Group related files in feature directories (e.g., `lib/src/features/auth/`).
- Expose public APIs from `lib/` (e.g., via a main entry point file matching the package name).
- Keep private implementations inside `lib/src/`.

### One Class Per File
- Each file must contain exactly one class or enum, regardless of relationship.
- The file name should match the class or enum name in snake_case.
- Only use Dart's `library` directive when grouping related files via `part` and `part of` directives. Files without `part` directives must not include a `library` directive.

**✅ Using library directive to group related files:**
```dart
// lib/src/models/auth_method.dart
part of 'auth_result.dart';

enum AuthMethod { basicAuth, oauth }
```

```dart
// lib/src/models/auth_result.dart
library;

part 'auth_method.dart';

class AuthResult {
  // Implementation
}
```

---

## JSON Handling

### Avoid Code Generation
- Avoid packages like `json_serializable` that generate opaque classes.
- Prefer explicit, readable manual parser and serializer code over generated code.
- Keep JSON parsing logic transparent and maintainable.

### Use fromJson Factory Constructors and toJson Methods
**✅ Preferred serialization pattern:**
```dart
class DeviceConfig {
  const DeviceConfig({
    required this.id,
    required this.name,
    required this.saltLevel,
  });

  final String id;
  final String name;
  final double saltLevel;

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    try {
      return DeviceConfig(
        id: json['id'] as String? ?? 
            throw ArgumentError('Missing required field: id'),
        name: json['name'] as String? ?? 
            throw ArgumentError('Missing required field: name'),
        saltLevel: (json['saltLevel'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      throw FormatException('Failed to parse DeviceConfig from JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'saltLevel': saltLevel,
    };
  }
}
```

---

## Testing

### Test Organization
- Mirror the `lib/` structure in `test/`.
- Write unit tests for services, repositories, and models.
- Run tests using the `dart test` command.

### Testing Best Practices
- Test business logic and edge cases in isolation.
- Mock network APIs, databases, or filesystem operations using a mocking library or interface implementations.
- Verify error cases and assertions are thrown correctly.

```dart
import 'package:test/test.dart';

void main() {
  group('DeviceConfig', () {
    test('parses correctly from valid json', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'dev_123',
        'name': 'Brine Tank 1',
        'saltLevel': 4.5,
      };
      
      final DeviceConfig config = DeviceConfig.fromJson(json);
      expect(config.id, equals('dev_123'));
      expect(config.name, equals('Brine Tank 1'));
      expect(config.saltLevel, equals(4.5));
    });

    test('throws ArgumentError when required fields are missing', () {
      final Map<String, dynamic> invalidJson = <String, dynamic>{
        'name': 'Brine Tank 1',
      };
      
      expect(
        () => DeviceConfig.fromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```
