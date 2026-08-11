# Berry Collector

A simple Flutter + Flame game about picking berries out of a thicket. Built as an example project for testing the Thicket world model system. The game provides enough structure (entity types, scoring, game state, component hierarchy) for the Thicket agent to learn meaningful things from development activity.

## Gameplay

Berries spawn at random positions on a green field. Tap a berry to collect it and earn points. Four berry types appear with different frequencies and point values:

| Berry | Points | Rarity |
|-------|--------|--------|
| Raspberry | 1 | Common |
| Blueberry | 2 | Moderate |
| Blackberry | 3 | Uncommon |
| Golden Berry | 5 | Rare |

Each round lasts 60 seconds. When time runs out, the final score is displayed with an option to play again.

## Role in the Thicket System

This project serves as a test subject for Thicket. Once registered with the Thicket backend (via the setup wizard), development events (commits, file changes) can be sent to the agent. The agent learns about this project's architecture, patterns, and conventions by examining the code and building a persistent world model.

Things the agent can learn from this project:

- The Flame component hierarchy and how entities are structured
- The weighted spawn probability system for berry types
- How game state (score, timer, playing flag) is managed
- The MVC pattern used for the Flutter screen layer
- The relationship between berry types (enum) and their visual representation (components)
