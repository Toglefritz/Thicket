# Thicket

**Thicket is an architecture for long-lived AI agents that continuously learn from the environments in which they operate.**

Most AI agents are transient. They receive a task, gather context, produce a result, and then discard much of what they learned. When they return to the same project later, they often spend additional inference reconstructing information they have already encountered.

Thicket gives agents a persistent **world model** that stores and structures knowledge accumulated over time. Instead of repeatedly rebuilding context from raw artifacts, an agent can retrieve its existing understanding, update it as new information arrives, and use that accumulated experience during future work.

The goal is an agent that does not merely complete tasks autonomously, but becomes increasingly experienced in the environment where it works.

## Core Idea

A Thicket agent operates continuously rather than only inside a chat loop.

It can observe events, retrieve relevant prior knowledge, reason about how new information changes its understanding, investigate gaps or contradictions, and update its world model.

For example, a software engineering agent might learn from:

* source code and commits;
* issues and pull requests;
* specifications and documentation;
* meeting transcripts and team discussions;
* test failures and incidents.

Over time, the agent might develop an understanding of project architecture, historical decisions, dependencies, conventions, failure modes, and unresolved questions.

Future tasks can then begin from accumulated experience instead of starting from scratch.

## Architecture

Thicket is organized into three independent layers.

```text
┌──────────────────────────────────────┐
│          Agent / LLM Layer           │
│                                      │
│ Observe • reason • investigate • act │
│                                      │
│ Repositories • Docs • Messages       │
│ Meetings • Tasks • APIs • Events     │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│           Interface Layer            │
│                                      │
│ MCP • REST • SDKs • integrations     │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│           World Model Layer          │
│                                      │
│ Entities • relationships • ontology  │
│ observations • provenance • history  │
└──────────────────────────────────────┘
```

### World Model

The world model stores the agent's accumulated understanding.

Rather than acting only as a collection of memories, it represents entities and relationships within the environment. A software engineering world model might contain concepts such as:

```text
Project
Subsystem
Decision
Requirement
Dependency
FailureMode
Constraint
Incident
```

Thicket also supports agent-defined ontologies, allowing the agent to introduce new concepts and relationships when its existing representation is insufficient.

### Interface Layer

The interface layer exposes world-model operations without coupling agents to a particular storage implementation.

The current implementation uses an MCP server, but other interfaces such as REST APIs, SDKs, or direct integrations can be added independently.

### Agent / LLM Layer

The agent layer connects the world model to the outside world.

It observes information from connected systems, decides what matters, retrieves relevant knowledge, and updates the world model as its understanding changes.

The agent may also investigate missing information or ask questions when it identifies an important knowledge gap.

## Why Persistent World Models?

Large context windows and retrieval systems can provide access to information, but they still often require agents to repeatedly reconstruct what that information means.

Thicket explores a different approach: convert useful experience into a durable, structured representation that can be reused later.

This may improve more than continuity. If an agent can retrieve a compact representation of knowledge it previously derived from large amounts of raw context, it may require fewer tokens, fewer tool calls, and less time to complete future tasks at the same quality.

## More Than Memory

Thicket is not intended to be an append-only memory store.

A useful world model may need to:

* generalize repeated observations;
* represent relationships;
* preserve provenance;
* revise outdated beliefs;
* identify uncertainty;
* resolve contradictions;
* forget information that is no longer useful;
* create new abstractions.

The goal is not simply to help an agent remember more.

It is to help the agent build a better representation of its environment through experience.

## Example Use Cases

Thicket is designed for environments where an agent repeatedly works within the same evolving domain.

An engineering agent in a software project could learn architecture and historical decisions. A research agent could track concepts, evidence, and competing hypotheses. An operational agent could accumulate knowledge about incidents and remediation strategies. An organizational agent could learn from documents, meetings, messages, and project artifacts.

The underlying architecture remains the same even though the resulting world models may look very different.

## Future Direction

The initial focus is on enabling individual agents to accumulate and reuse experience.

Future work may explore:

* automatic consolidation and forgetting;
* alternative retrieval strategies;
* confidence and uncertainty modeling;
* shared knowledge between agents;
* specialization;
* automated comparison of world-model strategies;
* evolutionary optimization of agent cognition.
