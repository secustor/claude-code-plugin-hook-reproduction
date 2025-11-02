#!/bin/bash
# Simple Stop hook that outputs JSON (PLUGIN VERSION)

# Read input from STDIN (Claude Code passes hook data as JSON)
read -r input

# Output valid JSON response
echo '{"continue":true,"stopReason":"","suppressOutput":false,"decision":"block","reason":"🔌 PLUGIN HOOK executed successfully from plugins/test-plugin/hooks/"}'

# Exit successfully
exit 0
