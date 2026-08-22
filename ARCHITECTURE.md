# Architecture

This document contains Mermaid diagram sources for Thicket's architecture at multiple levels of detail. 

## 1. System Overview

The end-to-end flow from a developer's IDE to the persistent world model.

```mermaid
flowchart LR
    subgraph Developer Machine
        IDE[Agentic IDE]
        MCP[Thicket MCP Server<br/>stdio, local process]
        Hook[Agent Hooks<br/>recall + record]
    end

    subgraph Google Cloud
        CR[Cloud Run<br/>Thicket Agent]
        FS[(Firestore<br/>World Model)]
        GEM[Gemini 3.5 Flash<br/>via Genkit]
    end

    subgraph Integrations
        GIT[Git Post-Commit<br/>Webhook]
    end

    IDE <-->|JSON-RPC| MCP
    Hook -->|prompt injection| IDE
    MCP -->|HTTPS| CR
    GIT -->|POST /events| CR
    CR <-->|read/write| FS
    CR <-->|generate + tools| GEM
```

**Flow:**

1. The IDE's AI agent triggers hooks (recall before responding, record after tasks).
2. The MCP server translates tool calls into HTTPS requests to the Thicket Agent on Cloud Run.
3. The Agent uses Genkit + Gemini 3.5 Flash to reason about events and decide what to store.
4. Knowledge is persisted as entities in Firestore, scoped per project.
5. External integrations (e.g., git post-commit hooks) send events directly to Cloud Run.

## 2. Agent Cognitive Loop

How the Thicket Agent processes an event and updates the world model.

```mermaid
flowchart TD
    E[Event Received<br/>source, type, payload] --> R[Recall<br/>retrieve relevant<br/>existing knowledge]
    R --> A[Analyze<br/>compare event against<br/>current understanding]
    A --> D{New knowledge<br/>discovered?}
    D -->|Yes| U[Update<br/>remember new entities<br/>forget obsolete ones]
    D -->|No| S[Skip<br/>no changes needed]
    U --> SUM[Summarize<br/>return what was learned]
    S --> SUM
    SUM --> DONE[Done]

    style E fill:#e8f5e9,stroke:#4caf50
    style R fill:#e3f2fd,stroke:#2196f3
    style A fill:#fff3e0,stroke:#ff9800
    style U fill:#e8f5e9,stroke:#4caf50
    style SUM fill:#f3e5f5,stroke:#9c27b0
```

The agent has up to 20 tool-calling turns per event, allowing it to iteratively recall, reason, and update in a single processing cycle.

## 3. Google Cloud Infrastructure

The specific GCP services and how they connect.

```mermaid
flowchart TB
    subgraph Firebase
        FH[Firebase Hosting<br/>Setup Web App<br/>thicket-505111.web.app]
    end

    subgraph Cloud Run
        AGENT[Thicket Agent<br/>Dart native binary<br/>Shelf HTTP server]
    end

    subgraph Firestore
        DB[(Cloud Firestore<br/>projects / entities<br/>per-project partitioning)]
    end

    subgraph Vertex AI / Google AI
        GEMINI[Gemini 3.5 Flash<br/>via genkit_google_genai]
    end

    subgraph OAuth
        GAUTH[Google OAuth 2.0<br/>user authentication]
    end

    FH -->|POST /projects| AGENT
    AGENT -->|Genkit generate| GEMINI
    AGENT -->|read/write documents| DB
    FH -->|consent flow| GAUTH
    GAUTH -->|access token| AGENT

    style FH fill:#ffecb3,stroke:#ffa000
    style AGENT fill:#bbdefb,stroke:#1976d2
    style DB fill:#c8e6c9,stroke:#388e3c
    style GEMINI fill:#e1bee7,stroke:#7b1fa2
    style GAUTH fill:#ffcdd2,stroke:#d32f2f
```

**Services used:**

| Service | Purpose |
|---------|---------|
| Cloud Run | Hosts the Thicket Agent (event processor + registration API) |
| Firestore | Persistent storage for the world model (entities, relationships, observations) |
| Gemini 3.5 Flash | Reasoning engine for event analysis and knowledge extraction |
| Firebase Hosting | Serves the setup web application |
| Google OAuth 2.0 | Authenticates users during project registration |
| Genkit | Orchestrates LLM calls with tool-use loops |

## 4. MCP Server (Interface Layer)

How the local MCP server bridges the IDE and the cloud.

```mermaid
flowchart LR
    subgraph IDE Process
        AG[AI Agent]
    end

    subgraph MCP Server Process
        STDIO[stdio transport<br/>JSON-RPC 2.0]
        TOOLS[Tool Registry]
        SEARCH[search<br/>semantic lookup]
        REMEMBER[remember<br/>create/update entity]
        RECALL[recall<br/>retrieve by collection]
        FORGET[forget<br/>delete entity]
    end

    subgraph Cloud
        API[Thicket Agent<br/>Cloud Run]
    end

    AG <-->|stdin/stdout| STDIO
    STDIO --> TOOLS
    TOOLS --> SEARCH
    TOOLS --> REMEMBER
    TOOLS --> RECALL
    TOOLS --> FORGET
    SEARCH -->|HTTPS| API
    REMEMBER -->|HTTPS| API
    RECALL -->|HTTPS| API
    FORGET -->|HTTPS| API
```

The MCP server exposes four tools to the IDE's AI agent:

| Tool | Description |
|------|-------------|
| `search` | Semantic search across the world model using embeddings |
| `remember` | Store or update an entity in a named collection |
| `recall` | Retrieve all entities from a collection (or one by ID) |
| `forget` | Delete an entity that is no longer relevant |

## 5. World Model Data Structure

How knowledge is organized in Firestore.

```mermaid
erDiagram
    PROJECT ||--o{ COLLECTION : contains
    COLLECTION ||--o{ ENTITY : stores
    ENTITY {
        string id PK
        string summary
        string collection
        map data
        timestamp createdAt
        timestamp updatedAt
    }
    PROJECT {
        string projectId PK
        string projectName
        string storageMode
        string agentUrl
        string gcpProjectId
    }
```

The agent defines its own schema per project. Common collections include:

- `architecture` — system structure, component relationships
- `conventions` — coding patterns and style decisions
- `decisions` — rationale behind significant choices
- `gotchas` — failure modes, constraints, things to watch for
- `schema` — meta-record describing the world model's current structure

## 6. Setup Flow

How a new user goes from zero to a working Thicket integration.

```mermaid
sequenceDiagram
    participant U as User
    participant WEB as Setup App<br/>(web or CLI)
    participant G as Google OAuth
    participant API as Thicket Agent<br/>(Cloud Run)
    participant FS as Firestore

    U->>WEB: Start setup
    WEB->>G: Redirect to consent
    G->>U: Show consent page
    U->>G: Approve
    G->>WEB: Return access token
    WEB->>API: POST /projects (token + name)
    API->>FS: Create project partition
    FS-->>API: Confirm
    API-->>WEB: projectId + apiToken + agentUrl
    WEB->>U: Download config files
    Note over U: Place files in project directory
    Note over U: Run dart pub global activate
    Note over U: Open project in IDE
```
