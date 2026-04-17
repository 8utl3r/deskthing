#!/usr/bin/env bash
# SSH to Windows PC. Delegates to scripts/windows-pc/ssh-windows.sh
# Used by SK1 flashing workflow. Credentials: scripts/ugoos/.env or scripts/windows-pc/.env
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../windows-pc/ssh-windows.sh" "$@"
