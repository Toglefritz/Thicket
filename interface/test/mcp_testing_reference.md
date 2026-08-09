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
Saves or updates a generic JSON entity inside a specified collection.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--collection` (Required): The target collection (e.g. `experiences`, `beliefs`, `concepts`, or any custom namespace).
*   `--id` (Optional): Unique identifier to assign or update. If omitted, a new ID is generated.
*   `--data` (Required): A JSON-serialized object containing any fields desired. Note: Because arguments are parsed as key-value pairs, `--data` will expect a JSON string when tested from CLI harnesses.

```bash
# Save a new experience episode with a generated ID
dart run tool/mcp_call.dart remember \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --collection experiences \
  --data '{"kind":"constraintDiscovered","summary":"Vanilla CSS only","content":"User prefers pure vanilla CSS over Tailwind."}'

# Update a specific belief using its ID
dart run tool/mcp_call.dart remember \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --collection beliefs \
  --id my-belief-id \
  --data '{"claim":"Thicket uses dynamic JSON schemas","confidence":1.0}'
```

### 4. `recall`
Queries experience entities from the world model.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--collection` (Required): The target collection to query.
*   `--id` (Optional): Filters results to only this specific entity ID. If omitted, lists all entities in the collection (newest first).

```bash
# List all saved beliefs
dart run tool/mcp_call.dart recall \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --collection beliefs

# Retrieve a specific experience episode by its ID
dart run tool/mcp_call.dart recall \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --collection experiences \
  --id 06c4eab1
```

### 5. `forget`
Deletes a specified entity from a collection.
*   `--projectPath` (Required): Absolute path to the project root.
*   `--collection` (Required): The target collection name.
*   `--id` (Required): The identifier of the entity to delete.

```bash
dart run tool/mcp_call.dart forget \
  --projectPath /Users/scotthatfield/Documents/Projects/thicket \
  --collection experiences \
  --id 06c4eab1
```
