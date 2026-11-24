#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Missing .env file in $(pwd)" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

TAG="${TAG:-1.0.0}"
WAIT_SECONDS="${WAIT_SECONDS:-60}"

wait_for_healthy() {
  local name="$1"
  local elapsed=0

  while [ "$elapsed" -lt "$WAIT_SECONDS" ]; do
    if ! docker inspect "$name" >/dev/null 2>&1; then
      echo "Container $name disappeared while waiting for health." >&2
      exit 1
    fi

    local status
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name")"

    if [ "$status" = "healthy" ]; then
      echo "$name is healthy."
      return 0
    fi

    if [ "$status" = "unhealthy" ]; then
      echo "$name became unhealthy. Last 20 log lines:" >&2
      docker logs --tail 20 "$name" >&2 || true
      exit 1
    fi

    sleep 2
    elapsed=$((elapsed + 2))
  done

  echo "Timed out after ${WAIT_SECONDS}s waiting for $name to become healthy. Last 20 log lines:" >&2
  docker logs --tail 20 "$name" >&2 || true
  exit 1
}

recreate_container() {
  local name="$1"
  docker rm -f "$name" >/dev/null 2>&1 || true
}

# 1. Create networks and named volume only if missing
docker network inspect frontend-net >/dev/null 2>&1 || docker network create frontend-net >/dev/null
docker network inspect backend-net >/dev/null 2>&1 || docker network create --internal backend-net >/dev/null
docker volume inspect pgdata >/dev/null 2>&1 || docker volume create pgdata >/dev/null

# 2. Start postgres on backend-net only
recreate_container postgres
docker run -d \
  --name postgres \
  --restart unless-stopped \
  --network backend-net \
  --env-file .env \
  -v pgdata:/var/lib/postgresql/data \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  --health-cmd "pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-shopdb}" \
  --health-interval 5s \
  --health-timeout 3s \
  --health-retries 12 \
  postgres:17-alpine >/dev/null

wait_for_healthy postgres

# 3. Start backends on backend-net, then attach each to frontend-net
for svc in catalog inventory orders; do
  recreate_container "$svc"
  docker run -d \
    --name "$svc" \
    --restart unless-stopped \
    --network backend-net \
    --env-file .env \
    "shop-${svc}:${TAG}" >/dev/null
  docker network connect frontend-net "$svc"
done

for svc in catalog inventory orders; do
  wait_for_healthy "$svc"
done

# 4. Start frontend on frontend-net only, publishing port 80
recreate_container frontend
docker run -d \
  --name frontend \
  --restart unless-stopped \
  --network frontend-net \
  -e "SERVER_NAME=${SERVER_NAME:-shoplite.test}" \
  -p 80:80 \
  "shop-frontend:${TAG}" >/dev/null

wait_for_healthy frontend

echo "ShopLite stack is up (TAG=${TAG})."
