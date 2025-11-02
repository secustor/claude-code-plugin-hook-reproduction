# Plugin Hook Output Capture Bug Reproduction

Minimal reproduction case for https://github.com/anthropics/claude-code/issues/10875

## Issue

Plugin hooks execute successfully but Claude Code never captures/parses their JSON output, while identical inline hooks work correctly.

## Setup

This repo contains two nearly-identical bash Stop hooks:

1. **Inline hook** (configured in `.claude/settings.json`): `hooks/entrypoints/stop.sh`
2. **Plugin hook** (auto-discovered from plugin): `plugins/test-plugin/hooks/entrypoints/stop.sh`

Both hooks:
- Read input from STDIN
- Output valid JSON with `decision: "block"` and a reason message
- Exit with code 0

The only difference is the reason text to identify which hook executed.

## Reproduction Steps

### Test 1: Plugin hook only

1. Edit `.claude/settings.json` and comment out the inline hook configuration:
   ```json
   {
     "hooks": {
       "Stop": []
     },
     "enabledPlugins": {
       "test-plugin": true
     }
   }
   ```

2. Run Claude Code in this directory
3. Trigger a Stop hook (let Claude finish a response)
4. Check debug logs at `~/.claude/debug/[session-id].txt`

**Expected:** Should see `Hooks: Checking initial response for async: {...}` and `Successfully parsed hook JSON output`

**Actual:** Skips directly from `Matched 1 unique hooks` to `Hooks: getAsyncHookResponseAttachments called` with no parsing

### Test 2: Inline hook only

1. Edit `.claude/settings.json` to enable inline hook and disable plugin:
   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "hooks/entrypoints/stop.sh"
             }
           ]
         }
       ]
     },
     "enabledPlugins": {
       "test-plugin": false
     }
   }
   ```

2. Run Claude Code in this directory
3. Trigger a Stop hook
4. Check debug logs

**Expected:** Should see parsing messages and "Inline hook executed successfully" in output

**Actual:** Works correctly - logs show `Hooks: Checking initial response` and `Successfully parsed hook JSON output`

## Manual Testing

Both hooks output valid JSON when tested manually:

```bash
# Test plugin hook
echo '{}' | ./plugins/test-plugin/hooks/entrypoints/stop.sh
# Output: {"continue":true,"stopReason":"","suppressOutput":false,"decision":"block","reason":"Plugin hook executed successfully"}

# Test inline hook
echo '{}' | ./hooks/entrypoints/stop.sh
# Output: {"continue":true,"stopReason":"","suppressOutput":false,"decision":"block","reason":"Inline hook executed successfully"}
```

## Debug Log Comparison

**Working (inline hook):**
```
[DEBUG] Matched 1 unique hooks for query "no match query"
[DEBUG] Hooks: Checking initial response for async: {"continue":true,...}
[DEBUG] Successfully parsed and validated hook JSON output
```

**Broken (plugin hook):**
```
[DEBUG] Matched 1 unique hooks for query "no match query"
[DEBUG] Hooks: getAsyncHookResponseAttachments called
[DEBUG] Hooks: checkForNewResponses called
```

The plugin hook output is never captured or parsed.

## Environment

- Platform: darwin
- Version: 2.0.31
