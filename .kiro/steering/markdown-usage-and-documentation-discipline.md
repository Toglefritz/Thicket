---
title: Markdown Usage and Documentation Discipline
description: Prevents AI agents from creating unnecessary Markdown files. Defines when documentation belongs in the repository versus in chat, and enforces version control hygiene.
tags:
  - markdown
  - documentation
  - ai-behavior
  - repository-hygiene
---


# Markdown Usage & Documentation Discipline

This document defines rules governing **when and how Markdown files are created or modified**. Its purpose is to prevent repository clutter, reduce version-control noise, and ensure that documentation serves the project—not the AI agent's need to explain itself.

## 1. Core Rule

### **Do Not Create New Markdown Files Unless Explicitly Asked**

The AI agent **must not create new Markdown documents** unless the human developer explicitly requests their creation.

This includes, but is not limited to:

- Summary documents
- Progress reports
- "What was done" write-ups
- Architecture explanations addressed to the user
- Design rationales written as standalone files

If the user did not ask for a new document, **do not create one**.

## 2. Acceptable Markdown Operations

### 2.1 Modifying Existing Project Documentation
The AI **may modify existing Markdown files** when doing so directly improves the project, such as:

- Updating an existing `README.md`
- Adding setup instructions to an existing documentation file
- Correcting inaccuracies or outdated information
- Expanding documentation **only when it reflects implemented code**

All changes must:
- Be scoped to the file's existing purpose
- Avoid speculative or future-facing content
- Reflect the current state of the codebase

### 2.2 Markdown as a First-Class Project Artifact
Markdown files are treated as **project artifacts**, not communication channels.

They should:
- Describe how to use the system
- Document public APIs or behaviors
- Explain configuration or build steps

They should **not**:
- Explain what the AI just did
- Justify design choices to the reader
- Narrate development steps
- Act as a proxy for chat responses

## 3. Explicitly Forbidden Markdown Patterns

The following are **not allowed** unless explicitly requested:

- ❌ "Summary.md"
- ❌ "Implementation Notes.md"
- ❌ "AI Decisions.md"
- ❌ "Changes Overview.md"
- ❌ "Next Steps.md"
- ❌ Any document written *to the human developer*

Markdown files that "talk to the reader" instead of documenting the project are considered **repository noise**.

## 4. Where Human-Directed Information Belongs

### 4.1 Use Chat for Explanations
Any of the following must be communicated **in chat**, not in the repository:

- What was implemented
- Why a decision was made
- What could be done next
- Trade-offs or alternatives
- Requests for feedback or confirmation

Chat is ephemeral and contextual.  
Repositories are durable and structural.

Do not confuse the two.

## 5. Version Control Hygiene

Unnecessary Markdown files:

- Obscure meaningful changes
- Increase review burden
- Create long-term maintenance costs
- Pollute project history

The AI should behave as if **every committed file must be maintained indefinitely**.

If a document would not still be valuable in six months, it does not belong in the repository.

## 6. Safe Default Behavior

When in doubt:

1. **Do not create a new Markdown file**
2. Prefer chat
3. Ask the human developer if documentation changes are desired

Silence is preferable to clutter.

## 7. Summary Rule (Non-Negotiable)

> **Markdown files document the project.  
> Chat communicates with the human.  
> Never reverse these roles.**

Adhering to this rule is essential for keeping the codebase clean, readable, and maintainable.
