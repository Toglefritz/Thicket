# Thicket

Thicket is a persistent world model for AI coding agents. It gives agents cross-session memory, allowing them to accumulate durable understanding of a software project rather than starting from scratch every time a new session begins.

Modern coding agents are capable within a single session, but they behave like engineers who are new to a project every time a conversation starts. They repeatedly inspect the same files, rediscover architectural constraints, revisit previously rejected approaches, and reconstruct knowledge that an experienced engineer would already possess. Without persistent memory, each new session risks relearning lessons that earlier sessions already paid for.

Thicket solves this by providing a structured, persistent knowledge layer that any MCP-compatible agent can use to remember experiences, form beliefs about the system, and build a project-specific understanding that improves over time.

## How It Works

Thicket runs as a local MCP (Model Context Protocol) server. The coding agent performs its normal work (reasoning, inspecting code, making changes) while Thicket provides persistent knowledge that survives across sessions.

```text
┌──────────────────────────────┐
│      AI Coding Agent         │
│                              │
│  Kiro / Cursor / Codex / ... │
└───────────────┬──────────────┘
                │
                │ MCP (stdio)
                ▼
┌──────────────────────────────┐
│            Thicket           │
│                              │
│  recall    — retrieve prior  │
│  remember  — record new      │
│  learn     — form beliefs    │
│  define    — shape ontology  │
└───────────────┬──────────────┘
                │
                ▼
┌──────────────────────────────┐
│     Persistent Storage       │
│  ~/.thicket/projects/<id>/   │
└──────────────────────────────┘
```

Any MCP-compatible agent can integrate with Thicket. The world model is stored independently from the agent itself, so the same accumulated knowledge is available regardless of which LLM or development tool is used.

## The Problem

AI coding agents today have no persistent project understanding. Every session starts cold. This leads to:

- Repeated rediscovery of the same architectural constraints
- Repeated violations of project-specific patterns and conventions
- Failure to learn from previously rejected approaches
- No memory of debugging outcomes or root-cause investigations
- Inability to build the kind of project intuition that experienced engineers develop over months

Thicket addresses each of these by giving agents a structured way to remember, retrieve, and revise project knowledge across sessions.

## World Model Structure

Thicket organizes knowledge into three layers:

```text
Experience Layer (Episodes)
         │
         ▼
Knowledge Layer (Beliefs)
         │
         ▼
Ontology Layer (Concepts)
```

**Episodes** record significant experiences: tasks performed, constraints discovered, approaches that failed, debugging outcomes, unexpected interactions between subsystems. They provide historical evidence from which more general knowledge can be derived.

**Beliefs** represent the agent's current understanding of the system: which components own which responsibilities, which patterns are used, which dependencies exist, which approaches to avoid. Beliefs carry confidence scores and provenance links to the episodes that support them.

**Concepts** define the vocabulary the agent uses to organize its knowledge. The ontology adapts to each project: a Flutter app might develop concepts like Screen, StateManager, and NavigationFlow, while an embedded firmware project might develop HardwarePeripheral, Driver, and TimingConstraint.

## Agent Interaction Flow

```text
New development task
        │
        ▼
recall — retrieve relevant knowledge
        │
        ▼
Agent performs development work
        │
        ▼
Agent encounters significant information
        │
        ▼
remember — record the experience
        │
        ▼
learn — update beliefs about the system
        │
        ▼
Knowledge persists for future sessions
```

The world model is treated as prior knowledge, not absolute truth. The current state of the codebase remains authoritative. When new evidence contradicts an existing belief, the agent revises its understanding rather than clinging to outdated information.

## MCP Tools

Thicket exposes the following tools through the Model Context Protocol:

| Tool | Purpose |
|------|---------|
| `initialize_project` | Sets up Thicket for a new project (creates identity and storage) |
| `remember` | Records a significant experience as an episode |
| `recall` | Retrieves relevant episodes from the world model |
| `get_version` | Returns the current Thicket server version |

## Adaptive Ontology

Thicket does not impose a fixed schema on every project. The ontology is organized into three tiers with increasing flexibility:

- **Built-in primitives**: The structural types Thicket itself needs (Episode, Belief, Concept). Fixed and not agent-modifiable.
- **Recommended concepts**: A starter set of concepts that work for most software projects (Component, Pattern, Constraint, Convention). Modifiable with rationale.
- **Project-defined concepts**: Abstractions the agent creates as it learns what matters for a specific project. Tracked with required rationale to prevent unnecessary churn.

Each concept carries origin metadata, lifecycle status (proposed, active, deprecated, retired), and a rationale field. This biases the system toward stability while allowing evolution when the agent has a compelling reason.

## Storage

World model data is stored as human-readable JSON files on the local filesystem:

```text
~/.thicket/projects/<project-id>/
  episodes/
    <episode-id>.json
  beliefs/
    <belief-id>.json
  concepts/
    <concept-id>.json
```

Each project is linked to its storage through a `.thicket/project.json` identity file in the project root. The identity contains a stable, human-readable identifier (e.g. "mossy-lantern-a3f2") that persists even if the project is moved or renamed.

Storage is designed to be inspectable. Every piece of knowledge the agent has accumulated can be read, audited, and understood by a human developer.

## Setup

### Prerequisites

- Dart SDK 3.12.2 or later

### Installation

```bash
git clone https://github.com/Toglefritz/thicket.git
cd thicket
dart pub get
```

### Running the Server

```bash
dart run bin/thicket.dart
```

The server communicates over stdio using the MCP protocol (newline-delimited JSON-RPC 2.0).

### MCP Configuration

Add Thicket to your IDE's MCP configuration. For Kiro, create or update `.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "thicket": {
      "command": "dart",
      "args": ["run", "bin/thicket.dart"],
      "cwd": "/path/to/thicket"
    }
  }
}
```

### Initialize a Project

Before using Thicket with a project, initialize it:

```bash
dart run tool/mcp_call.dart initialize_project --projectPath /path/to/your/project
```

This creates `.thicket/project.json` in the project and sets up the centralized storage directory.

### Testing Tools Manually

A CLI client is included for testing MCP tool calls outside of an agent:

```bash
dart run tool/mcp_call.dart get_version
dart run tool/mcp_call.dart recall --projectPath /path/to/project
dart run tool/mcp_call.dart remember --projectPath /path/to/project \
  --kind constraintDiscovered \
  --summary "Database migrations must run before server start" \
  --content "The server crashes if pending migrations exist..."
```

## Architecture

Thicket is implemented as a Dart MCP server with the following structure:

```text
lib/src/
  models/
    core/         — base entity type (id, timestamps, revision)
    experience/   — Episode and EpisodeKind
    knowledge/    — Belief and BeliefStatus
    ontology/     — Concept, ConceptOrigin, ConceptStatus
    project/      — ProjectIdentity
  server/
    mcp_server.dart       — JSON-RPC dispatch and protocol handling
    json_rpc_transport.dart — stdio transport layer
    json_rpc_message.dart  — message parsing
    mcp_tool.dart          — tool registration interface
    tools/
      initialize_project_tool.dart
      remember_tool.dart
      recall_tool.dart
      get_version_tool.dart
      project_resolver.dart
  storage/
    entity_store.dart              — filesystem persistence
    revision_conflict_exception.dart — concurrency control
  utils/
    id_generator.dart — human-readable ID generation
```

Key architectural decisions:

- **Protocol-native**: Built directly on JSON-RPC 2.0 without an SDK dependency, giving full control over the MCP implementation.
- **Agent-agnostic**: Any MCP-compatible client can use Thicket. The world model is not tied to a specific LLM or IDE.
- **Inspectable storage**: JSON files on disk, not an opaque database. Developers can read, audit, and understand everything the agent knows.
- **Optimistic concurrency**: Revision-based conflict detection prevents silent data loss when multiple sessions interact with the same world model.
- **Adaptive ontology with friction**: The agent can evolve the conceptual structure of its knowledge, but stability is favored over churn through required rationale and tiered origin controls.

## Project Identity

Each project is identified by a human-readable slug (e.g. "quiet-compass-71dc") generated at initialization time. This identifier:

- Remains stable even if the project directory is moved or renamed
- Serves as the directory name under `~/.thicket/projects/`
- Is stored in `.thicket/project.json` alongside a human-readable project name

This design decouples the world model from filesystem paths, allowing projects to be relocated without losing their accumulated knowledge.

## License

MIT
