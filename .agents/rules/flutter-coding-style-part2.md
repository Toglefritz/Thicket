---
title: Flutter Coding Standards - Project Organization & Data Handling
description: File organization, JSON serialization, localization (i18n), and testing standards for Flutter and Dart.
tags:
  - flutter
  - dart
  - mobile
  - serialization
  - localization
  - testing
---

# Flutter and Dart Coding Standards - Project Organization & Data Handling

## File Organization

### Naming Conventions
- Use snake_case for file names
- Use PascalCase for class names
- Use camelCase for variable and method names
- Suffix controller files with `_controller.dart`
- Suffix view files with `_view.dart`
- Suffix route files with `_route.dart`

### Directory Structure
- Group related files in feature directories
- Place shared components in `lib/components/`
- Place business logic in `lib/services/`
- Keep models in `lib/models/`
- Organize by feature, not by file type

### One Class Per File
- Each file must contain exactly one class or enum, regardless of relationship
- The file name should match the class or enum name in snake_case
- This architecture makes maintenance, testing, and code navigation easier
- Only use Dart's `library` directive when the file also declares `part` directives that group related files into a single logical unit. Files without `part` directives must not include a `library` directive.

**✅ Preferred structure for related classes:**
```
lib/services/authentication/models/
├── auth_method.dart         # Contains AuthMethod enum
├── auth_credentials.dart    # Contains AuthCredentials class
└── auth_result.dart         # Contains AuthResult class
```

**✅ Using library directive to group related files:**
```dart
// lib/services/authentication/models/auth_method.dart
part of 'auth_result.dart.dart';

enum AuthMethod { basicAuth, google, apple }
```

```dart
// lib/services/authentication/models/auth_credentials.dart
part of 'auth_method.dart';

class AuthCredentials {
  // Implementation
}
```

```dart
// lib/services/authentication/models/auth_result.dart
library;

part 'auth_method.dart';
part 'auth_credentials.dart';

class AuthResult {
  // Implementation
}
```

**✅ Importing a library:**
```dart
// Import individual files as needed
import '../models/auth_method.dart';
import '../models/auth_credentials.dart';
import '../models/auth_result.dart';
```

**❌ Never put multiple classes in one file:**
```dart
// Don't do this - even for related classes
class AuthCredentials { }
class AuthResult { }
enum AuthMethod { basicAuth, google, apple }
```

### File Naming Rules
- Use snake_case for file names
- File name should reflect the primary class/enum it contains
- For related classes, use a descriptive library name
- Avoid generic names like `models.dart` or `utils.dart`

## JSON Handling

### Avoid Code Generation
- Avoid packages like `json_serializable` that generate opaque classes
- Prefer explicit, readable code over generated code
- Keep JSON parsing logic transparent and maintainable

### Use fromJson Factory Constructors
**✅ Preferred pattern:**
```dart
class BrineDevice {
  const BrineDevice({
    required this.id,
    required this.name,
    required this.saltLevel,
    required this.batteryLevel,
  });

  final String id;
  final String name;
  final double saltLevel;
  final double batteryLevel;

  factory BrineDevice.fromJson(Map<String, dynamic> json) {
    return BrineDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      saltLevel: (json['saltLevel'] as num).toDouble(),
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'saltLevel': saltLevel,
      'batteryLevel': batteryLevel,
    };
  }
}
```

### JSON Best Practices
- Always use explicit type casting with `as` operator
- Handle nullable fields appropriately
- Use `toDouble()` for numeric values that should be doubles
- Include both `fromJson` and `toJson` methods for complete serialization
- Validate required fields and throw meaningful errors for missing data
- Document expected JSON structure in class documentation

### Error Handling in JSON Parsing
```dart
factory BrineDevice.fromJson(Map<String, dynamic> json) {
  try {
    return BrineDevice(
      id: json['id'] as String? ?? 
          throw ArgumentError('Missing required field: id'),
      name: json['name'] as String? ?? 
          throw ArgumentError('Missing required field: name'),
      saltLevel: (json['saltLevel'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble() ?? 0.0,
    );
  } catch (e) {
    throw FormatException('Failed to parse BrineDevice from JSON: $e');
  }
}
```

## Localization and Internationalization

### Use Localizable Strings
- Never hard-code strings directly in widgets
- All user-facing text must use the `l10n/app_localizations.dart` dependency
- Add strings to `frontend/lib/l10n/app_en.arb`
- Generate localizable strings using `flutter gen-l10n`

**✅ Preferred localization pattern:**
```dart
// In widget
Text(AppLocalizations.of(context)!.welcomeMessage)

// In app_en.arb
{
  "welcomeMessage": "How can I help you today?",
  "@welcomeMessage": {
    "description": "A message welcoming the user to the app"
  }
}
```

**❌ Never hard-code strings:**
```dart
// Don't do this
Text('How can I help you today?')
```

### ARB File Requirements
- Every string must include a description using the `@` prefix
- Use descriptive key names that indicate the string's purpose
- Include context about where and how the string is used

**✅ Required ARB format:**
```json
{
  "buttonSave": "Save",
  "@buttonSave": {
    "description": "Label for the save button in forms"
  },
  "errorNetworkConnection": "Unable to connect to the server. Please check your internet connection.",
  "@errorNetworkConnection": {
    "description": "Error message shown when network connection fails"
  }
}
```

### Advanced Localization Features

#### Placeholders for Variables
```json
{
  "welcomeUser": "Welcome back, {userName}!",
  "@welcomeUser": {
    "description": "Personalized welcome message for returning users",
    "placeholders": {
      "userName": {
        "type": "String",
        "description": "The user's display name"
      }
    }
  }
}
```

```dart
// Usage in widget
Text(AppLocalizations.of(context)!.welcomeUser(user.name))
```

#### Pluralization
```json
{
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Shows the number of items in a list",
    "placeholders": {
      "count": {
        "type": "int",
        "description": "The number of items"
      }
    }
  }
}
```

```dart
// Usage in widget
Text(AppLocalizations.of(context)!.itemCount(items.length))
```

### Localization Workflow
1. Add new strings to `frontend/lib/l10n/app_en.arb`
2. Run `flutter gen-l10n` to generate the localization classes
3. Import `AppLocalizations` in your widget files
4. Use `AppLocalizations.of(context)!.stringKey` to access strings
5. Always include null-safety operator `!` when accessing localized strings

### Best Practices
- Group related strings with consistent prefixes (e.g., `error*`, `button*`, `title*`)
- Keep descriptions clear and include context about usage
- Use meaningful key names that describe the string's purpose
- Test localization by switching device language settings
- Consider text expansion when designing UI layouts for different languages

## Testing

### Test Organization
- Mirror the `lib/` structure in `test/`
- Write unit tests for controllers and services
- Write widget tests for complex UI components
- Use mocking for external dependencies

### Testing Best Practices
- Test business logic in controllers
- Mock Firebase services in tests
- Use `fake_http_client` for HTTP mocking
- Test error scenarios and edge cases
