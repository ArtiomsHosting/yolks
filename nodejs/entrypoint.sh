#!/bin/bash
set -euo pipefail

prompt() {
    printf '\033[1m\033[33mcontainer~ \033[0m%s\n' "$1"
}

export TZ="${TZ:-UTC}"
INTERNAL_IP="$(ip -o route get 1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' || true)"
export INTERNAL_IP

cd /home/container

prompt 'node -v'
node -v

if [[ -z "${STARTUP:-}" ]]; then
    printf 'No startup command was provided.\n' >&2
    exit 1
fi

PARSED="$(printf '%s' "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')"

prompt "$PARSED"
exec /bin/bash -c "$PARSED"
