---
title: Development Behavior
description: Guides AI agents toward simple, iterative development. Prevents speculative architecture, large initial commits, and premature abstraction.
tags:
  - ai-behavior
  - development-process
  - iterative
  - simplicity
---

# Development Behavior 
**Principle: Build Simply, Build Iteratively**


## 1. Core Philosophy

### 1.1 Start Small, Then Grow
Always begin with the **simplest possible solution** that meaningfully advances the project.

- Prefer **one clear use case** over multiple speculative ones.
- Prefer **one service/module** over many.
- Prefer **real behavior** over stubbed abstractions.

> If a feature is not required *right now*, it should not exist *yet*.

### 1.2 Iterative Construction Over Big First Drafts
Codebases should **evolve**, not appear fully formed.

The AI should:
- Build systems **one small piece at a time**
- Pause after each meaningful increment
- Allow the human developer to review, test, and redirect before proceeding

Avoid delivering:
- Large API surfaces all at once
- Multiple unused services or modules
- Placeholder methods for "future ideas"

## 2. Decision Rules for Adding Complexity

Before adding **any** new abstraction, service, file, or public API, ask:

1. **Is this required to meet the current goal?**
2. **Would the system still function without it?**
3. **Is there a concrete behavior being implemented right now?**

If the answer to any of these is **no**, do not add it.

## 3. Feature Development Guidelines

### 3.1 One Capability at a Time
Each development step should focus on **one clearly defined capability**.

**Good example:**
- Implement a single Bluetooth service that validates one pairing mechanism end-to-end

**Bad example:**
- Implement five services covering performance, security, diagnostics, and metadata before any of them are used

### 3.2 Avoid Speculative APIs
Do not create APIs "for later."

- No empty methods
- No TODO-only services
- No placeholder enums or flags for imagined future modes

APIs should emerge **because usage requires them**, not because they might be useful someday.

### 3.3 Prefer Concrete Implementations First
Start with direct, explicit implementations.

Only introduce:
- Abstractions
- Interfaces
- Base classes
- Configuration layers

**after** multiple concrete implementations prove they are needed.

## 4. Code Structure Expectations

### 4.1 Minimal Surface Area
Expose the smallest public interface possible.

- Keep classes focused
- Keep files short
- Keep responsibilities obvious

If something is not used externally, it should not be public.

## 5. Collaboration Workflow

### 5.1 Pause Frequently
After completing a meaningful increment:

- Stop
- Summarize what was added
    - Prefer providing summaries in a chat interface
    - Do not write unnecessary Markdown or other files in the codebase unless requested
- Ask whether to proceed or adjust direction

The AI should **not assume forward momentum without confirmation**.

### 5.2 Let the Human Drive Scope
The human developer controls:
- When complexity is added
- When refactoring occurs
- When new features are introduced

The AI's role is to **support**, not preempt, these decisions.

## 6. Red Flags to Avoid

The following patterns are explicitly discouraged:

- ❌ "Just in case" services
- ❌ Fully fleshed-out architectures without usage
- ❌ Large initial commits that define an entire system
- ❌ Framework-like designs for small, focused tools
- ❌ Multiple testing or diagnostic layers before core functionality exists

## 7. Success Criteria

The AI is succeeding when:

- The codebase is easy to understand at any snapshot in time
- Each file has a clear reason to exist
- New developers could explain the system after reading it once
- Features feel *earned*, not speculative
