---
title: Writing Style - Markdown, Punctuation & Formatting Conventions
description: Markdown & README guidelines, vocabulary selection rules, punctuation/formatting constraints, and Dart-specific doc preferences.
tags:
  - writing
  - markdown
  - punctuation
  - formatting
---

# Writing Style Steering - Markdown, Punctuation & Formatting Conventions

## Markdown and README Style

### Write documentation that is useful during real work

README and architecture documentation should help a contributor do something concrete:
- understand the system
- set up the project
- navigate the architecture
- make safe changes
- troubleshoot known issues

Documentation should not read like product copy.

### Prefer informative section names

Use headings that describe the actual content.

Prefer:
- `Architecture`
- `Project Structure`
- `How State Flows Through the Feature`
- `Platform Constraints`
- `Local Development`
- `Testing Strategy`

Avoid vague headings such as:
- `Overview Stuff`
- `Important Notes`
- `Things to Know`

### Explain tradeoffs explicitly

When a design is non-obvious, document the tradeoff directly.

Example:

```md
This feature keeps state in the controller rather than distributing it across
widgets. The main reason for this approach is that scan lifecycle management is
shared across multiple UI states, and centralizing it avoids duplicate cleanup
logic.
```

---

## Style Rules to Follow

### Prefer concrete nouns and verbs

Prefer:
- `stores`
- `tracks`
- `normalizes`
- `converts`
- `coordinates`
- `prevents`
- `represents`

Over vague verbs like:
- `handles`
- `deals with`
- `works with`
- `manages` when a more specific verb is available

### Avoid empty emphasis

Do not add adjectives unless they carry real meaning.

Avoid words such as:
- `simple`
- `easy`
- `powerful`
- `robust`
- `clean`
- `efficient`

Unless the surrounding text explains specifically what makes the thing simple, efficient, or robust.

### Avoid generic summary sentences

Do not end comments with empty wrap-up lines such as:
- `This ensures smooth operation.`
- `This improves the user experience.`
- `This makes the system more maintainable.`

If a benefit matters, name the specific mechanism.

---

## Punctuation and Formatting Conventions

This section defines specific punctuation and formatting rules intended to avoid common AI-generated writing patterns and maintain a more natural engineering voice.

### Do not use em-dashes

Never use em-dashes in any form.

Avoid using `—` entirely, even when it might seem grammatically acceptable.

Instead, restructure the sentence using:
- commas
- parentheses
- separate sentences

Example:

Bad:
```text
This controller manages scan state — including lifecycle, caching, and filtering.
```

Better:
```text
This controller manages scan state, including lifecycle, caching, and filtering.
```

### Avoid decorative separators

Do not use visual separators such as:
- `---`
- `===`
- `***`
- long strings of dashes or equals signs

These patterns are often associated with generated or stylized output and add noise without improving clarity.

Use normal Markdown structure instead:
- headings
- spacing
- short sections

### Avoid emojis unless explicitly requested

Do not include emojis in comments, documentation, or Markdown.

Emojis should only be used when the user explicitly asks for them.

### Prefer standard sentence punctuation

Use conventional punctuation:
- periods to end sentences
- commas for clause separation
- parentheses for side notes when necessary

Avoid overusing:
- ellipses (`...`)
- excessive exclamation points
- stacked punctuation such as `!!` or `?!`

### Avoid "AI list cadence"

Do not create long sequences of short, repetitive bullet points that follow the same rhythm.

Prefer grouping related ideas into:
- short paragraphs
- smaller, meaningful lists

Lists should feel intentional, not mechanically generated.

### Keep formatting minimal and functional

Formatting should support readability, not draw attention to itself.

Avoid:
- excessive bolding
- excessive italics
- visual styling that does not add meaning

Use emphasis sparingly and only when it clarifies structure or intent.

---

## Commenting Philosophy

### Comment for future maintenance

Write comments for the person who will revisit the code later and need to answer questions like:
- Why is this structured this way?
- What assumption is this depending on?
- What can break if this changes?
- What part of the system owns this behavior?

### Prefer durable comments

Write comments that will remain true even if small implementation details change.

Prefer documenting intent and contract over transient implementation steps.

---

## Language Conventions

### Use qualified caution when needed

When behavior depends on platform APIs, timing, or external state, say so directly.

Examples:
- `On Android, this callback may arrive more than once for the same device.`
- `This value is only meaningful after service discovery has completed.`
- `The timeout is intentionally conservative because connection latency varies by platform.`

---

## Dart-Specific Preferences

Because this style is often applied in Dart and Flutter projects, use Dartdoc consistently for public APIs.

### Public API guidance

- Document public classes, methods, enums, extensions, and important public fields.
- Use summary-first Dartdoc style.
- Add additional paragraphs only when they provide meaningful architectural or behavioral context.
- Use bracket links such as `[BleDevice]` when referencing related types.

### Example Dartdoc style

```dart
/// Represents a device discovered during an active BLE scan.
///
/// This model contains the information that is stable and broadly useful across
/// platforms. Platform-specific scan details should be normalized before they
/// are stored here.
class BleDevice {
  /// The identifier used by the current platform to refer to this device.
  final String address;

  /// The best human-readable name currently available for the device.
  ///
  /// This value may be empty when the peripheral does not advertise a name.
  final String name;
}
```

---

## What Good Writing in This Style Looks Like

Good project writing in this style is:
- clear without sounding generic
- technical without being stiff
- explanatory without being verbose for its own sake
- structured around intent and architecture
- willing to document tradeoffs and constraints directly
- free of fluff, hype, and empty filler

---

## Final Instruction for AI Systems

When generating comments or documentation for this codebase:
- match the local engineering voice, not generic AI documentation voice
- explain design intent, architecture, and constraints where helpful
- keep wording direct and grounded
- do not inflate the prose
- do not comment obvious code
- prefer precise, useful explanation over blanket completeness

When in doubt, write the kind of comment that would genuinely help a skilled engineer understand the code six months from now.
