#!/bin/bash
# Read input from stdin
INPUT=$(cat)

# Extract transcript path
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcriptPath // empty')

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo '{}'
  exit 0
fi

REMINDER_TEXT="If you have completed a milestone or reached a significant project state, please consider recording"

HAS_PROMPTED=false
HAS_RECORDED=false
HAS_MODIFIED=false

# Read transcript.jsonl line-by-line
while IFS= read -r line || [ -n "$line" ]; do
  if [ -z "$line" ]; then
    continue
  fi

  # Check if we already prompted the reminder
  if echo "$line" | grep -q "$REMINDER_TEXT"; then
    HAS_PROMPTED=true
  fi

  # Check for tool calls in this line
  TOOL_CALLS=$(echo "$line" | jq -c '.tool_calls[]?' 2>/dev/null)
  if [ -n "$TOOL_CALLS" ]; then
    while IFS= read -r tool_call || [ -n "$tool_call" ]; do
      if [ -z "$tool_call" ]; then
        continue
      fi
      
      NAME=$(echo "$tool_call" | jq -r '.name // empty')
      
      # Check if a modifying tool was called
      if [ "$NAME" = "write_to_file" ] || [ "$NAME" = "replace_file_content" ] || [ "$NAME" = "multi_replace_file_content" ] || [ "$NAME" = "run_command" ]; then
        HAS_MODIFIED=true
      elif [ "$NAME" = "call_mcp_tool" ]; then
        # Check ToolName inside args
        TOOL_NAME=$(echo "$tool_call" | jq -r '.args.ToolName // empty')
        if [ "$TOOL_NAME" = "remember" ] || [ "$TOOL_NAME" = "learn" ] || [ "$TOOL_NAME" = "define_concept" ]; then
          HAS_RECORDED=true
        fi
      fi
    done <<< "$TOOL_CALLS"
  fi
done < "$TRANSCRIPT_PATH"

if [ "$HAS_MODIFIED" = "true" ] && [ "$HAS_RECORDED" = "false" ] && [ "$HAS_PROMPTED" = "false" ]; then
  jq -n \
    --arg text "$REMINDER_TEXT" \
    '{
      decision: "continue",
      reason: ("You are about to finish the task. " + $text + " any relevant experiences, beliefs, and/or concepts using the Thicket MCP tools (`remember`, `learn`, `define_concept`) before exiting.")
    }'
else
  echo '{}'
fi
