# Thicket Setup CLI

A command-line tool for registering projects with the Thicket platform and configuring IDE integrations. Performs the same actions as the Flutter setup wizard but runs entirely in the terminal.

## What It Does

The CLI guides you through a four-step wizard:

1. **Sign in with Google** — Opens your browser for OAuth2 authentication.
2. **Configure your project** — Collects a project name and directory, then registers with the Thicket backend.
3. **Select your IDE** — Choose between Antigravity or Kiro.
4. **Install MCP server and hooks** — Activates the Thicket MCP server globally and writes configuration files for your selected IDE.

After completion, the following files are written to your project:

- `.thicket/project.json` — Non-sensitive project metadata (safe to commit).
- `.thicket/credentials.json` — API token (automatically added to `.gitignore`).
- MCP server configuration at the path expected by your IDE.
- Agent hooks that prompt your AI agent to recall and record knowledge.

## Prerequisites

- [Dart SDK](https://dart.dev/get-dart) 3.0 or newer.
- A Google account for OAuth sign-in.

## Running with Dart

From the repository root:

```bash
cd setup_cli
dart pub get
```

Set the OAuth credentials as environment variables, then run:

```bash
export GOOGLE_OAUTH_CLIENT_ID=<your-client-id>
export GOOGLE_OAUTH_CLIENT_SECRET=<your-client-secret>
dart run bin/setup_cli.dart
```

The CLI reads credentials from environment variables at runtime. Alternatively, you can bake them in at compile time (see below).

## Running a Pre-Compiled Binary

If a compiled binary is available (e.g., from GitHub Releases), no Dart SDK is required:

```bash
./thicket-setup
```

The binary is self-contained and has zero runtime dependencies. OAuth credentials are embedded at compile time.

## Compiling to a Native Binary

To produce a standalone executable with credentials baked in:

```bash
dart compile exe bin/setup_cli.dart \
  -DGOOGLE_OAUTH_CLIENT_ID=<your-client-id> \
  -DGOOGLE_OAUTH_CLIENT_SECRET=<your-client-secret> \
  -o thicket-setup
```

This produces a single binary (~6.6 MB) that can be distributed without requiring the Dart SDK on the target machine. The credentials are embedded at compile time so end users don't need to set environment variables.

### Cross-Platform Builds

Dart compiles to native code for the current platform. To produce binaries for other platforms, compile on each target OS:

| Platform        | Output name              |
|-----------------|--------------------------|
| macOS (ARM)     | `thicket-setup-macos`    |
| Linux (x64)     | `thicket-setup-linux`    |
| Windows (x64)   | `thicket-setup.exe`      |

## Overriding the Backend URL

For local development or alternative deployments, set the `THICKET_API_URL` environment variable:

```bash
export THICKET_API_URL=http://localhost:8080
dart run bin/setup_cli.dart
```

Or bake it in at compile time:

```bash
dart compile exe bin/setup_cli.dart \
  -DGOOGLE_OAUTH_CLIENT_ID=<id> \
  -DGOOGLE_OAUTH_CLIENT_SECRET=<secret> \
  -DTHICKET_API_URL=http://localhost:8080 \
  -o thicket-setup
```

## Project Structure

```
setup_cli/
  bin/
    setup_cli.dart            # Entry point — orchestrates the wizard flow
  lib/src/
    api.dart                  # Thicket backend API calls (register/join)
    auth.dart                 # Google OAuth2 loopback sign-in
    console.dart              # ANSI colors, formatted output, input prompts
    file_writer.dart          # Writes project.json, credentials.json, .gitignore
    hook_installer.dart       # Agent hook installation (Antigravity + Kiro)
    ide_type.dart             # IdeType enum
    mcp_installer.dart        # MCP server activation and config writing
  pubspec.yaml
```
