# MCP Testing Reference

This document serves as a guide for manually testing the Thicket Model Context Protocol (MCP) server. 

Testing is done using the [mcp_call.dart](file:///Users/scotthatfield/Documents/Projects/thicket/interface/tool/mcp_call.dart) test harness script. The harness handles spawning the MCP server subprocess, performing the protocol handshake, executing the tool call, printing the formatted results, and shutting down.

## Command Syntax

All commands must be executed from the **`interface` package root**:

```bash
cd interface
dart run tool/mcp_call.dart <tool_name> [--argumentName value ...]
```

## Tool Test Commands

### 1. `get_version`
Verifies server connectivity and outputs the current version. Takes no arguments.

```bash
dart run tool/mcp_call.dart get_version
```

### 2. `initialize_project`
Initializes Thicket for a target directory path.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--projectName` (Optional): A friendly name for the project. Defaults to the directory name.
*   `--storageMode` (Optional): Either `centralized` (default, stores in `~/.thicket`) or `inRepo` (stores in `.thicket/world_model`).

```bash
# Initialize using default centralized mode
dart run tool/mcp_call.dart initialize_project \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket

# Initialize using Git-friendly in-repo mode
dart run tool/mcp_call.dart initialize_project \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --storageMode inRepo
```

### 3. `remember`
Records a new experience episode in the world model database.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--kind` (Required): Category of experience. Must be one of:
    *   `taskPerformed`
    *   `constraintDiscovered`
    *   `approachFailed`
    *   `implementationRejected`
    *   `unexpectedInteraction`
    *   `debuggingOutcome`
    *   `observation`
*   `--summary` (Required): A concise summary sentence.
*   `--content` (Required): Extended description with reasoning or details.

```bash
dart run tool/mcp_call.dart remember \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --kind constraintDiscovered \
  --summary "Vanilla CSS styling constraint" \
  --content "We must use pure Vanilla CSS for layouts. Avoid using utility frameworks like Tailwind CSS unless explicitly requested."
```

### 4. `recall`
Retrieves experience episodes from the world model.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--kind` (Optional): Filters results to only this experience category.

```bash
# Retrieve all episodes
dart run tool/mcp_call.dart recall \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket

# Retrieve only constraints discovered
dart run tool/mcp_call.dart recall \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --kind constraintDiscovered
```

### 5. `learn`
Stores a structured belief or hypothesis in the world model.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--claim` (Required): Concise statement of what the agent believes to be true.
*   `--rationale` (Required): Reasoning or evidence supporting the claim.
*   `--confidence` (Required): Numeric certainty between `0.0` and `1.0`.

```bash
dart run tool/mcp_call.dart learn \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --claim "Interface package uses thicket path dependency" \
  --rationale "Allows developing interface and world model in local root-level silos" \
  --confidence 1.0
```

### 6. `define_concept`
Introduces an abstraction node to the project's ontology.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--name` (Required): Noun or noun phrase representing the concept.
*   `--description` (Required): Definition and usage instructions.

```bash
dart run tool/mcp_call.dart define_concept \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --name "InterfaceBridge" \
  --description "A component that exposes world model storage APIs to external transport layers like JSON-RPC and REST."
```
