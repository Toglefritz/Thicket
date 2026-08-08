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
          toolCall: {
            name: "call_mcp_tool",
            args: {
              ServerName: "thicket",
              ToolName: "recall",
              Arguments: {
                projectPath: $path
              },
              toolAction: "Recalling prior experiences from world model",
              toolSummary: "Recall experiences"
            }
          }
        }
      ]
    }'
else
  echo '{"injectSteps":[]}'
fi
