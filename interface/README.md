# Thicket - Interface Layer

The **Interface Layer** is the bridge between external agentic systems and the Thicket **World Model Layer**. 

As described in the root-level [README.md](file:///Users/scotthatfield/Documents/Projects/thicket/README.md), Thicket isolates its core world model logic (entities, ontology, and persistence) from how agents consume and manipulate that knowledge. This package (`thicket_interface`) implements that abstraction boundary.

---

## Architecture & Purpose

The Interface Layer is designed to be multi-protocol and host-agnostic. It translates incoming protocol requests (e.g., JSON-RPC over stdio, HTTP REST, or direct library calls) into operations performed on the underlying `world_model` package.

```text
┌─────────────────────────────────────────────────────────┐
│                    Agent / LLM Layer                    │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼ Protocol-specific Request
┌─────────────────────────────────────────────────────────┐
│                    Interface Layer                      │
│                                                         │
│  ┌──────────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │    MCP Server    │  │  REST API *  │  │  SDKs *   │  │
│  │ (Stdio/JSON-RPC) │  │  (HTTP/JSON) │  │  (Dart)   │  │
│  └────────┬─────────┘  └──────┬───────┘  └─────┬─────┘  │
└───────────┼───────────────────┼────────────────┼────────┘
            └───────────────────┴────────────────┘ Calls Thicket API
                                │
                                ▼
┌─────────────────────────────────────────────────────────┐
│                    World Model Layer                    │
│                 (package:thicket/thicket.dart)          │
└─────────────────────────────────────────────────────────┘
* Planned interface integrations
```

### Current Protocol: Model Context Protocol (MCP)

The initial implementation exposes Thicket’s capabilities as a **Model Context Protocol (MCP)** server. MCP is an open standard that allows developer tools and IDEs (such as Cursor, Windsurf, or custom agent frameworks) to expose context and tools to LLMs in a unified way.

The MCP server exposes the following tools:

| Tool Name | Purpose |
|---|---|
| `get_version` | Returns the current server version (handshake validation). |
| `initialize_project` | Configures Thicket for a target project path, creating `.thicket/project.json` and setting up the storage mode (Centralized vs. In-Repo). |
| `remember` | Records a significant experience as an `Episode` (constraints, failures, successes). |
| `recall` | Retrieves recent `Episode` entities, sorted by creation date with optional filtering. |
| `learn` | Formulates a structured `Belief` about the codebase with a claim, confidence, and status. |
| `define_concept` | Formalizes a domain-specific `Concept` in the project's ontology. |

---

## Getting Started

### Prerequisites

The interface package depends on the core world model package. Ensure they are aligned locally:
- Dart SDK `^3.12.2`

### Running the MCP Server

The server runs over stdio and expects newline-delimited JSON-RPC 2.0 messages:

```bash
cd interface
dart pub get
dart run bin/thicket.dart
```

### Running the Test Client

A CLI client is provided to test tool invocations interactively without an IDE host:

```bash
cd interface
# Check the server version
dart run tool/mcp_call.dart get_version

# Initialize a project
dart run tool/mcp_call.dart initialize_project --projectPath /absolute/path/to/project
```

### Running Unit Tests

Run the interface layer verification tests (e.g., verifying storage path resolution logic):

```bash
cd interface
dart test
```

---

## Future Interfaces

As this project expands, the `interface/` silo will incorporate other mechanisms for interacting with the Thicket world model:
*   **REST API**: A local HTTP server that exposes the world model tools via JSON payloads over REST, allowing non-Dart agents and web-based orchestrators to interact with Thicket.
*   **Dart SDK Plugins**: Direct programmatic bindings for embedding Thicket inside Dart/Flutter tools and workflows.
