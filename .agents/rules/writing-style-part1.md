---
title: Writing Style - Core Philosophy & Documentation Patterns
description: Core writing philosophy, tone guidelines, and documentation patterns for classes, methods, fields, and inline comments.
tags:
  - writing
  - documentation
  - tone
  - style
---

# Writing Style Steering - Core Philosophy & Documentation Patterns

This document defines the writing style that should be used for comments, doc comments, READMEs, architecture notes, and inline documentation in this codebase.

The goal is not to sound generic, academic, or AI-generated. The writing should sound like an experienced engineer explaining a system clearly, directly, and with respect for the reader's time.

## Core Style

### Write like an engineer teaching another engineer

Use a tone that is clear, grounded, practical, and explanatory.

Write with the assumption that the reader is capable and technical, but may not yet know the local architecture, design decision, or platform constraint being described.

Prefer writing that helps the reader build an accurate mental model over writing that merely sounds polished.

### Be clear before being clever

Prefer straightforward language over flourish.

Avoid marketing tone, hype, filler, or theatrical phrasing.

Do not write comments that feel promotional, overenthusiastic, or self-congratulatory.

Do not use vague phrases such as:
- `This powerful class...`
- `This amazing utility...`
- `Simply does...`
- `Just handles...`
- `Robust solution`
- `Seamlessly`

### Explain intent, not just mechanics

Good documentation in this style explains:
- what something does
- why it exists
- when it should be used
- what constraints or tradeoffs shaped it

Do not restate code in prose unless the restatement adds context.

Bad:

```dart
/// Sets the value of `isLoading` to true.
```

Better:

```dart
/// Marks the controller as loading before the request begins so the UI can
/// render a busy state and prevent duplicate submissions.
```

### Favor precision over brevity when precision matters

Be concise, but do not compress explanations so much that they become ambiguous.

A slightly longer explanation is preferable when it helps prevent misuse, confusion, or incorrect architectural assumptions.

---

## Tone

### Professional, calm, and matter-of-fact

The tone should be confident without sounding absolute.

Avoid sounding robotic, legalistic, or overly formal.

Avoid exaggerated certainty when discussing tradeoffs or behavior that depends on runtime conditions.

Use wording such as:
- `This allows...`
- `This is useful when...`
- `In this case...`
- `The main reason for this approach is...`
- `This is intentionally...`
- `This avoids...`

### Respect the reader

Do not write in a condescending teaching voice.

Do not overexplain obvious language syntax or standard library behavior unless it is relevant to a non-obvious design decision.

Assume the reader wants signal, not ceremony.

---

## Preferred Documentation Patterns

### For classes and major types

Class-level documentation should usually answer these questions:
1. What is this type responsible for?
2. Where does it fit in the architecture?
3. What should callers know before using it?
4. Are there important lifecycle, ownership, platform, or state assumptions?

Example:

```dart
/// Coordinates BLE scan state for the application.
///
/// This controller acts as the boundary between the UI layer and the central
/// Bluetooth APIs. It is responsible for starting and stopping scans,
/// normalizing scan events into application state, and exposing that state in a
/// form the view can render directly.
///
/// This controller does not interpret discovered devices beyond the needs of
/// scan management. Device-specific decisions belong in higher-level features.
```

### For methods and functions

Method documentation should focus on behavior and expectations, not line-by-line implementation.

Document:
- the method's purpose
- important side effects
- state expectations
- notable failure behavior
- timing or async behavior when relevant

Example:

```dart
/// Starts a new scan session and emits discovered devices through the returned
/// stream.
///
/// If a scan is already active, the existing session should be stopped before
/// calling this method again. This avoids overlapping platform scan requests,
/// which are not handled consistently across operating systems.
```

### For properties and fields

Document properties when the meaning, lifecycle, or usage is not obvious.

Good property comments often clarify one of these:
- source of truth
- ownership
- units or format
- nullable meaning
- lifecycle expectations

Example:

```dart
/// The most recently discovered peripherals keyed by their stable identifier.
///
/// This map is used to collapse repeat advertisements into a single logical
/// device entry while a scan session is active.
```

### For inline comments

Inline comments should usually explain one of the following:
- why a step is necessary
- why a less obvious approach is being used
- platform-specific behavior
- an invariant that must be preserved
- a temporary workaround and its boundary

Do not narrate obvious code.

Bad:

```dart
// Increment the index.
index++;
```

Better:

```dart
// The platform callback can report the same peripheral multiple times in rapid
// succession, so the existing entry is updated instead of appended.
```

---

## Structural Preferences

### Use short paragraphs and readable grouping

Prefer several short paragraphs over a wall of text.

In longer doc comments or Markdown documentation, group ideas into logical sections so the reader can scan the content quickly.

### Lead with the most important idea

Start comments with the primary purpose or key behavior.

Put secondary details, caveats, or edge cases after that.

### Use lists when they improve scanability

Use bullet lists when documenting:
- assumptions
- requirements
- constraints
- side effects
- migration steps
- decision criteria

Do not use lists when a normal paragraph would read more naturally.
