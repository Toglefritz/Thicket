---
title: Flutter Coding Standards - MVC & UI Architecture
description: MVC architecture pattern, state management with setState, widget composition rules, MaterialApp navigation, and strong typing standards for Flutter and Dart.
tags:
  - flutter
  - dart
  - mobile
  - mvc
  - coding-standards
---

# Flutter and Dart Coding Standards - MVC & UI Architecture

## Architecture Pattern: MVC

This project follows a strict MVC (Model-View-Controller) pattern for all screens:

### Route (Entry Point)
- Each screen has a `*_route.dart` file containing a `StatefulWidget`
- The route's `createState()` method returns the corresponding controller
- Routes are responsible only for defining the screen entry point

```dart
class WelcomeRoute extends StatefulWidget {
  const WelcomeRoute({super.key});

  @override
  State<WelcomeRoute> createState() => WelcomeController();
}
```

### Controller (Business Logic)
- Controllers extend `State<RouteWidget>` and handle all business logic
- Controllers manage state and call `setState()` to trigger UI updates
- All event handlers and data manipulation logic belongs in controllers
- Controllers pass themselves to views for access to state and methods

```dart
class WelcomeController extends State<WelcomeRoute> {
  // State variables
  late BrineDevice selectedDevice;

  // Event handlers
  void onDeviceSelected(BrineDevice device) {
    setState(() {
      selectedDevice = device;
    });
  }

  @override
  Widget build(BuildContext context) => WelcomeView(this);
}
```

### View (Presentation)
- Views are `StatelessWidget` classes that handle only UI presentation
- Views receive the controller as a parameter for accessing state and methods
- Views should be "dumb" and purely declarative
- No business logic should exist in view classes

```dart
class WelcomeView extends StatelessWidget {
  const WelcomeView(this.state, {super.key});

  final WelcomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI only - no business logic
    );
  }
}
```

## State Management

### Primary Pattern: setState()
- Use `setState()` as the primary state management mechanism
- Controllers call `setState()` to trigger UI rebuilds
- Avoid complex state management solutions (Provider, Bloc, Riverpod, etc.)
- Keep state management simple and predictable

### State Organization
- Declare state variables as instance variables in controllers
- Initialize state in `initState()` when needed
- Use `late` keyword for variables that will be initialized before first use

## Widget Composition

### Avoid Functions Returning Widgets
**❌ Don't do this:**
```dart
Widget _buildHeader() {
  return Container(
    child: Text('Header'),
  );
}
```

**✅ Do this instead:**
```dart
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Header'),
    );
  }
}
```

### Widget Extraction Guidelines
- Extract reusable UI components into separate widget classes
- Place screen-specific widgets in `components/` subdirectories
- Place shared widgets in `lib/components/`
- Prefer composition over inheritance

### Spacing and Layout
- Use `Padding` widgets for creating space between widgets, not `SizedBox`
- `Padding` provides more semantic meaning and better readability
- Use consistent padding values from the `Insets` class when available

**✅ Preferred spacing pattern:**
```dart
Column(
  children: [
    Text('First item'),
    Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text('Second item'),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text('Third item'),
    ),
  ],
)
```

**❌ Avoid SizedBox for spacing:**
```dart
Column(
  children: [
    Text('First item'),
    const SizedBox(height: 16.0),
    Text('Second item'),
    const SizedBox(height: 8.0),
    Text('Third item'),
  ],
)
```

**❌ Also Avoid Padding without a child for spacing:**
```dart
Column(
  children: [
    Text('First item'),
    const Padding(padding: EdgeInsets.only(bottom: 16.0)),
    Text('Second item'),
    const Padding(padding: EdgeInsets.only(bottom: 16.0)),
    Text('Third item'),
  ],
)
```

## Navigation

### Use MaterialApp Navigator
- Use the Navigator provided by MaterialApp
- Avoid named routes in favor of direct route construction
- Use `MaterialPageRoute` for standard transitions

**✅ Preferred navigation pattern:**
```dart
await Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (BuildContext context) => const TargetRoute(),
  ),
);
```

**❌ Avoid named routes:**
```dart
// Don't use this pattern
Navigator.pushNamed(context, '/target');
```

### Navigation Best Practices
- Use `pushReplacement` when the current screen should not be accessible via back button
- Pass data through constructor parameters rather than route arguments
- Handle navigation in controllers, not views

## Code Style

### Type Safety and Strong Typing
- All variables must be explicitly typed, including local variables within function bodies
- Never rely on type inference with `var` or `dynamic` unless absolutely necessary
- Use specific types rather than generic types when possible
- Prefer nullable types (`String?`) over dynamic when null values are expected

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
  var defaultStatus = 'pending'; // Could be inferred as String, but be explicit
  
  for (var app in applications) { // Type unclear
    var status = app.status ?? defaultStatus;
    var currentCount = statusCounts[status] ?? 0;
    statusCounts[status] = currentCount + 1;
  }
}
```

### Strong Typing Guidelines
- Declare the full type for collections: `List<String>`, `Map<String, int>`, `Set<Application>`
- Use explicit types for function parameters and return values
- Type cast with `as` operator when necessary, but prefer strong typing to avoid casts
- Use `late` keyword with explicit types for variables initialized after declaration
- Document complex generic types with meaningful names

### Linting
- Follow `very_good_analysis` linting rules
- Prefer single quotes for strings
- Always declare return types
- Use relative imports for local files
- Avoid lines longer than 80 characters when practical

### Documentation
- Document all public classes and methods
- Use `///` for documentation comments
- Include parameter descriptions for complex methods
- Document business logic and architectural decisions

### Error Handling
- Use specific exception types when possible
- Log errors with `debugPrint()` in debug mode
- Implement proper error boundaries in UI
- Handle async operations with try-catch blocks
