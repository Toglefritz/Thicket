# Thicket Agent Runtime

An event-driven autonomous codebase learning runtime built in Dart. It exposes a web service designed to run on **Google Cloud Run**, accepting normalized webhook events, analyzing them using Gemini, and updating the Thicket world model accordingly.

## Architecture

The runtime implements the **Agent / LLM Layer** of the Thicket system.

1.  **Ingestion Server**: A web API exposing the `/events` endpoint.
2.  **Autonomous Agent**: A stateful `GenerativeModel` (Gemini) equipped with tool functions (`remember`, `recall`, `forget`, `investigateCodebase`).
3.  **Autonomous Actions**:
    *   **Retrieve Context**: Recalls prior beliefs/experiences to establish baseline knowledge.
    *   **Investigate**: Read codebase files on demand to study commits, source code modifications, or document changes.
    *   **Generalize & Adapt**: Updates Thicket collections (`beliefs`, `experiences`, etc.) by writing new dynamic entities.

## API Documentation

### Webhook Event Endpoint
*   **Path**: `/events`
*   **Method**: `POST`
*   **Headers**: `Content-Type: application/json`

#### Request Body Schema
```json
{
  "source": "string",
  "eventType": "string",
  "projectPath": "string",
  "payload": {}
}
```

*   `source`: The origin of the event (e.g. `github`, `slack`, `gitlab`, `files`).
*   `eventType`: The category of trigger (e.g. `push`, `message`, `file_change`).
*   `projectPath`: Absolute path to the initialized Thicket project on the local disk.
*   `payload`: A flexible JSON payload containing event details (e.g. commits, modified files, message content).

## Local Setup & Testing

### 1. Resolve Dependencies
From the `agent/` directory:
```bash
dart pub get
```

### 2. Set Up Gemini API Key
Provide your Gemini credentials in your environment:
```bash
export GEMINI_API_KEY="your-gemini-api-key"
```
To obtain a key, visit [Google AI Studio](https://aistudio.google.com/app/api-keys).

### 3. Run the Server
```bash
dart run bin/server.dart
```
The server will start listening on port `8080` (or the port defined in the `PORT` environment variable).

### 4. Trigger a Test Event
Send a mock webhook push commit event to the running service using `curl`:
```bash
curl -X POST http://localhost:8080/events \
  -H "Content-Type: application/json" \
  -d '{
    "source": "github",
    "eventType": "push",
    "projectPath": "/Users/scotthatfield/Documents/Projects/thicket",
    "payload": {
      "ref": "refs/heads/main",
      "commits": [
        {
          "id": "abc1234",
          "message": "docs: document plain vanilla CSS requirement",
          "added": ["style.css"]
        }
      ]
    }
  }'
```

## Cloud Deployment (Without Docker)

You can deploy the Thicket Agent directly to **Google Cloud Run** using **Google Cloud Buildpacks**, completely bypassing the need to write or run Docker container configurations locally.

From the `agent/` directory, run:
```bash
gcloud run deploy thicket-agent \
  --source . \
  --set-env-vars GEMINI_API_KEY="your-gemini-api-key"
```

Google Cloud Buildpacks will automatically detect the Dart application, build a secure container image, push it to Artifact Registry, and deploy it to a Cloud Run URL.
