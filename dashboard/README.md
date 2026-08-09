# Thicket Dashboard

A Flutter developer console for inspecting and interacting with the Thicket system. It provides visibility into the world model, lets you dispatch simulated webhook events to the agent runtime, and records an audit trail of agent actions.

## Role in the Thicket Project

Thicket is organized into three layers: a **World Model** for persistent entity storage, an **Agent Runtime** that observes events and updates the world model via Gemini, and an **Interface Layer** that exposes these capabilities to tooling.

The dashboard is the primary developer-facing interface. It connects to:

- The **World Model** directly (reading and writing entity files on desktop, or using an in-memory simulation on web).
- The **Agent Runtime** via HTTP, dispatching webhook events to the agent's `/events` endpoint and displaying the reasoning response.

This removes the need to manually craft `curl` commands or browse raw JSON files when developing or debugging the agent's cognitive loop.

## Features

The dashboard currently provides three main capabilities, accessible via sidebar tabs:

1. **Webhook Simulator** — Compose and dispatch structured events (GitHub push, Slack message, filesystem change) to the running agent server. Displays the raw agent response including reasoning output.

2. **World Model Explorer** — Browse collections (beliefs, concepts, episodes, etc.) stored in the world model database. Inspect individual entity data, add new entities, edit existing ones, or delete them.

3. **Audit Log Stream** — Reverse-chronological history of events dispatched and actions taken, useful for tracing agent behavior during development.
