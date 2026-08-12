# Thicket Integrations

This directory contains integration scripts that connect development tools to the Thicket agent. Each integration sends structured events to the agent when something happens in your workflow, allowing the world model to learn from development activity.

## Available Integrations

### Git (post-commit hook)

Sends commit metadata (message, changed files, author, branch) to the Thicket agent after each commit. The agent processes the event asynchronously and updates the project's world model.

**Install:**

```bash
./integrations/git/install.sh /path/to/project
```

Or manually:

```bash
cp integrations/git/post-commit /path/to/project/.git/hooks/post-commit
chmod +x /path/to/project/.git/hooks/post-commit
```

**Requirements:**
- The project must have a `.thicket/project.json` (created by the setup wizard)
- `curl` must be available on PATH
- The Thicket agent must be reachable at the URL in the config

The hook runs `curl` in the background so it does not slow down commits.
