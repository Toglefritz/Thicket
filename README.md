# Thicket

Thicket is an experimental persistent world model for LLM-based software engineering agents. The project explores whether an AI coding agent can accumulate a durable understanding of a software system through repeated experience, rather than reconstructing that understanding each time a new agent session begins.

Modern coding agents are highly capable within a single session, but they often behave like engineers who are new to a project every time a new conversation begins. They repeatedly inspect the same files, rediscover architectural constraints, revisit previously rejected approaches, and reconstruct knowledge that an experienced engineer would already possess. They can also repeatedly make the same incorrect assumptions or violate the same project-specific patterns, even after those mistakes have been identified and corrected in earlier sessions. Without persistent knowledge of those corrections and the reasoning behind them, each new session risks relearning the same lessons from scratch.

## Motivation

Engineers who work on a codebase for months or years develop more than knowledge of its source code. They learn its architecture, conventions, history, failure modes, design tradeoffs, unusual constraints, and relationships between components. Much of this knowledge is not explicitly documented in any one place, but is instead gradually developed through experience working with the system.

Current LLM-based coding tools generally do not have an equivalent persistent understanding. Although they can inspect a repository, search documentation, and reason about the information available within their context window, much of the understanding developed while performing a task disappears when that context is discarded. Thicket investigates whether a persistent world model can preserve the useful parts of this experience and make them available to future agent sessions.

The goal is not simply to create a larger memory store or archive previous conversations. Thicket is concerned with how useful knowledge can be extracted from experience, represented over time, retrieved when relevant, revised as new evidence is encountered, and eventually consolidated or forgotten. It also explores whether the structure of the world model itself can evolve as the agent learns which concepts, relationships, and abstractions are important to the project.

The broader question is whether these mechanisms can allow an AI coding agent to develop something analogous to the project intuition accumulated by an experienced human engineer.

## Goals

Thicket is intended to explore several related questions:

* Can persistent project knowledge reduce the amount of context an agent must repeatedly rediscover?
* What information should an agent choose to remember after completing a task?
* How should architectural knowledge, design decisions, previous failures, and historical context be represented?
* Can an agent define and refine the concepts used by its own world model?
* How should project-specific concepts and relationships emerge from repeated experience?
* How should an agent revise its understanding when the codebase changes?
* How can stale or incorrect knowledge be detected and replaced?
* Can accumulated experience cause an agent to behave more like an engineer who has worked on a project for a long time?
* Which world-model representations provide the greatest improvement in correctness, efficiency, and continuity between sessions?

## Architecture

Thicket is designed as an independent local service that can be integrated with existing AI-assisted development tools. The coding agent remains responsible for reasoning about a task, inspecting and modifying source code, and using its normal development tools, while Thicket provides persistent knowledge that survives beyond an individual agent session.

```text
┌──────────────────────────────┐
│      AI Coding Agent         │
│                              │
│  Kiro / Cursor / Codex / ... │
└───────────────┬──────────────┘
                │
                │ MCP
                ▼
┌──────────────────────────────┐
│            Thicket           │
│                              │
│  Retrieval                   │
│  Experiences                 │
│  Beliefs                     │
│  Concepts                    │
│  Relationships               │
│  Evidence                    │
│  Knowledge revision          │
│  Model evolution             │
└───────────────┬──────────────┘
                │
                ▼
        Persistent Storage
```

The initial integration uses the Model Context Protocol (MCP), allowing compatible coding agents to query and update the world model through a small tool interface. Keeping Thicket independent from the coding agent also allows the same world model to be used with different models and development tools without tying its representation to a particular LLM provider or agent implementation.

## World Model

Thicket distinguishes between an agent's experiences working with a project and its current understanding of that project. It also separates the knowledge stored in the model from the conceptual structure used to represent that knowledge.

This creates three related layers:

```text
Experience
    │
    ▼
Project Knowledge
    │
    ▼
Project Ontology
```

Experiences capture what the agent encountered while working. Project knowledge captures what the agent currently believes to be true. The project ontology defines the concepts and relationships the agent uses to organize that knowledge.

### Episodes

Episodes record significant experiences encountered while performing development work. An episode might describe a task that was performed, an architectural constraint that was discovered, an approach that failed, the reason an implementation was rejected, an unexpected interaction between subsystems, or the outcome of a debugging investigation.

These episodes provide historical evidence from which more general knowledge can be derived. They are not intended to capture every action performed by the agent or become transcripts of entire coding sessions; instead, they preserve experiences that may influence how future work should be approached.

### Beliefs

Beliefs represent the agent's current understanding of the software system. They may describe which component owns a particular responsibility, which architectural patterns are normally used, which subsystems have important dependencies, which implementation approaches should be avoided, or which areas of the codebase are particularly fragile.

A belief can be associated with supporting evidence, confidence, timestamps, and relationships to other beliefs or experiences. Because the software system itself continues to evolve, beliefs are not assumed to be permanently correct. New evidence may strengthen a belief, reduce confidence in it, or cause it to be revised or superseded entirely.

This distinction allows Thicket to represent both what the agent experienced and what the agent currently believes about the system.

## Adaptive Project Ontology

Thicket does not assume that every software project should be described using the same fixed world-model schema. Different systems have different important abstractions, and part of the experiment is determining whether an agent can learn which concepts are useful for understanding the project in which it is working.

A Flutter application, for example, might lead an agent to develop concepts such as:

```text
Feature
Screen
StateManager
Repository
BackendService
NavigationFlow
DeviceCapability
```

An embedded firmware project might instead develop concepts such as:

```text
HardwarePeripheral
Driver
Protocol
InterruptHandler
Register
TimingConstraint
```

The agent can also define relationships between these concepts, such as:

```text
Screen uses StateManager
StateManager depends_on Repository
Feature implemented_by Screen
Driver controls HardwarePeripheral
```

These project-specific concepts are part of the world model rather than part of Thicket's fixed implementation.

Over time, the agent may introduce new concepts, refine existing ones, merge overlapping concepts, or split concepts that have proven too broad. In this way, the project ontology itself can evolve as the agent gains experience and develops a more useful conceptualization of the system.

A small set of underlying primitives remains stable so that Thicket can track provenance, revisions, relationships, and evidence. Above this substrate, however, the agent is free to shape the model around the project it is learning.

## Agent Interaction

A typical interaction begins when an agent receives a new development task. Before beginning substantial work, the agent queries Thicket for knowledge relevant to the task and incorporates that information into its working context.

```text
New development task
        │
        ▼
Recall relevant world-model knowledge
        │
        ▼
Agent performs normal development work
        │
        ▼
Agent discovers significant new information
        │
        ▼
Record experience
        │
        ├── update beliefs
        └── refine project ontology
        │
        ▼
World model persists for future sessions
```

As the agent works, it may encounter information that confirms existing knowledge, reveals something new, or contradicts what the world model previously believed. It may also encounter repeated patterns that suggest the world model itself should be reorganized around a new concept or relationship.

The world model is therefore treated as prior knowledge rather than as an unquestionable source of truth. The current software system remains authoritative, and an important part of the experiment is understanding how an agent should respond when its accumulated knowledge or conceptual structure no longer agrees with the system it is observing.

## MCP Interface

The initial world-model interface is intended to remain small while still allowing the agent to modify both the contents and the shape of the model.

Conceptually, the interface may include operations such as:

```text
recall(task)
```

Retrieves existing knowledge relevant to the current development task.

```text
remember(episode)
```

Records a significant experience encountered while performing development work.

```text
learn(belief)
```

Adds or revises persistent knowledge about the project based on newly acquired evidence.

```text
define_concept(...)
```

Introduces or refines a concept used to organize project knowledge.

```text
define_relationship(...)
```

Defines a meaningful relationship between concepts in the project ontology.

```text
revise_model(...)
```

Updates, merges, splits, or supersedes parts of the existing world model when the agent's understanding changes.

The exact interface is expected to evolve as the project explores how much freedom an agent should have to modify its own representation of a software system.

## Storage and Retrieval

Thicket favors flexible, inspectable storage that can accommodate evolving world-model structures without requiring a rigid relational schema. A document database is a natural fit because episodes, beliefs, concepts, relationships, evidence, and future world-model structures may not all share the same shape.

Documents can preserve both structured fields and flexible project-specific data, allowing the representation to evolve as the agent introduces new concepts or changes how existing knowledge is modeled. The persistence layer should support links between documents, revision history, provenance, and metadata such as confidence and timestamps without requiring the logical world model to mirror the physical storage schema.

Semantic search and embeddings can later be added to improve retrieval without making the embedding space itself the world model. Separating the representation of knowledge from the mechanisms used to retrieve it makes it possible to experiment with different approaches independently and to inspect why a particular piece of knowledge exists.

## Research Direction

Thicket is ultimately an experiment in longitudinal AI behavior. Instead of evaluating an agent only on isolated coding tasks, the project considers what happens when an agent performs a sequence of tasks against the same evolving software system and is able to retain selected knowledge between otherwise independent sessions.

A useful persistent agent should gradually require less rediscovery, retain important architectural knowledge, recognize relationships with previous work, learn from failed approaches, and adapt when previously correct knowledge becomes obsolete. More ambitiously, it should also develop increasingly useful abstractions for understanding the system rather than merely accumulating an increasingly large collection of historical facts.

This makes the evolution of the world model itself part of the research subject. An agent may begin with only general-purpose primitives and gradually develop a project-specific ontology shaped by the patterns, responsibilities, constraints, and abstractions it repeatedly encounters.

The long-term objective is to investigate whether persistent and adaptable world models can provide AI agents with something analogous to the accumulated project intuition developed by experienced human engineers, and to understand how those models should grow and change as the agents themselves gain experience.
