#!/bin/bash
# Read input from stdin
INPUT=$(cat)

# Extract fields
INVOCATION_NUM=$(echo "$INPUT" | jq -r '.invocationNum // 1')
WORKSPACE_PATH=$(echo "$INPUT" | jq -r '.workspacePaths[0] // empty')

if [ "$INVOCATION_NUM" -eq 1 ] && [ -n "$WORKSPACE_PATH" ]; then
  # Output the injection JSON
  jq -n \
    --arg path "$WORKSPACE_PATH" \
    '{
      injectSteps: [
        {
          ephemeralMessage: ("You are working in the Thicket workspace at: " + $path + ". Please recall any prior experiences and memories by calling the `recall` tool from the `thicket` MCP server with `projectPath` set to \"" + $path + "\".")
        }
      ]
    }'
else
  echo '{"injectSteps":[]}'
fi
