# Thicket Setup Wizard

A Flutter desktop app that registers a new project with the Thicket platform. Users sign in with their Google account, name their project, and the wizard handles registration with the Thicket backend. The resulting configuration is written to `.thicket/project.json` so the MCP server and agent can locate the project.

## How It Works

Thicket operates as a hosted service. All world model storage and agent processing happens on the Thicket backend (Cloud Run + Firestore). Users do not need their own GCP project or Gemini API key.

The setup flow:

1. **Sign in with Google** — Identifies the user via OAuth2. The browser opens to a consent page and a local server on port 9876 receives the redirect.
2. **Name the project** — The user provides a human-readable name for their project.
3. **Register** — The wizard calls `POST /projects` on the Thicket backend with the access token and project name. The backend creates a scoped partition in Firestore and returns a project ID, API token, and agent URL.
4. **Done** — The wizard writes `.thicket/project.json` with the returned configuration and displays a summary.

## Running

```bash
flutter run -d macos \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=client-id \
  --dart-define=GOOGLE_OAUTH_CLIENT_SECRET=client-secret
```

Optionally, override the backend URL for local development:

```bash
--dart-define=THICKET_API_URL=http://localhost:8080
```

## What Gets Written

After successful registration, `.thicket/project.json` in the current directory will contain:

```json
{
  "projectId": "quiet-elephant-71dc",
  "projectName": "Project Title",
  "createdAt": "2026-08-09T12:00:00.000Z",
  "storageMode": "cloud",
  "agentUrl": "https://thicket-agent-xxxx.run.app",
  "apiToken": "thk_..."
}
```

The MCP server reads this file to determine where to send events and how to authenticate.
