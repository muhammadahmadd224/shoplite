#!/usr/bin/env bash
set -euo pipefail

PURGE=false
if [ "${1:-}" = "--purge" ]; then
  PURGE=true
elif [ "$#" -gt 0 ]; then
  echo "Usage: $0 [--purge]" >&2
  exit 1
fi

for name in frontend orders inventory catalog postgres; do
  docker rm -f "$name" >/dev/null 2>&1 || true
done

docker network rm frontend-net backend-net >/dev/null 2>&1 || true

if [ "$PURGE" = true ]; then
  docker volume rm pgdata >/dev/null 2>&1 || true
  echo "Removed containers, networks, and pgdata volume."
else
  echo "Removed containers and networks (kept pgdata volume)."
fi
