#!/usr/bin/env bash
set -u

OUT="docs/evidence/phase1-tests.md"

{
  echo "# Phase 1 Isolation & Persistence Tests"
  echo ""

  echo "## Test 1: The app loads by name"
  echo '```bash'
  echo "curl -i -s http://shoplite.test"
  curl -i -s http://shoplite.test
  echo '```'
  echo ""

  echo "## Test 2: APIs work through nginx"
  echo '```bash'
  echo "curl -s http://shoplite.test/api/catalog/products"
  curl -s http://shoplite.test/api/catalog/products
  echo ""
  echo '```'
  echo ""

  echo "## Test 3: An order works end to end"
  echo '```bash'
  echo "curl -i -s -X POST http://shoplite.test/api/orders/orders -H 'Content-Type: application/json' -d '{\"productId\":1,\"quantity\":2}'"
  curl -i -s -X POST http://shoplite.test/api/orders/orders \
    -H 'Content-Type: application/json' \
    -d '{"productId":1,"quantity":2}'
  echo ""
  echo "curl -s http://shoplite.test/api/inventory/stock/1"
  curl -s http://shoplite.test/api/inventory/stock/1
  echo ""
  echo '```'
  echo ""

  echo "## Test 4: Backends aren't published"
  echo '```bash'
  for port in 3000 8081 8082; do
    echo "--- curl http://localhost:${port} ---"
    curl -s --max-time 3 "http://localhost:${port}" 2>&1 || true
  done
  echo "--- docker ps --format '{{.Names}} {{.Ports}}' ---"
  docker ps --format '{{.Names}} {{.Ports}}'
  echo '```'
  echo ""

  echo "## Test 5: The frontend network can't see Postgres"
  echo '```bash'
  echo "docker run --rm --network frontend-net busybox wget -T 3 -qO- http://postgres:5432"
  docker run --rm --network frontend-net busybox wget -T 3 -qO- http://postgres:5432 2>&1 || true
  echo '```'
  echo ""

  echo "## Test 6: Backends reach each other on backend-net"
  echo '```bash'
  echo "docker run --rm --network backend-net busybox wget -T 3 -qO- http://catalog:3000/health"
  docker run --rm --network backend-net busybox wget -T 3 -qO- http://catalog:3000/health 2>&1 || true
  echo ""
  echo '```'
  echo ""

  echo "## Test 7: Postgres has no internet"
  echo '```bash'
  echo "docker exec postgres wget -T 5 -qO- https://example.com"
  docker exec postgres wget -T 5 -qO- https://example.com 2>&1 || true
  echo '```'
  echo ""

  echo "## Test 8: Data survives a restart"
  echo '```bash'
  echo "./scripts/down.sh && TAG=1.0.0 ./scripts/up.sh && curl -s http://shoplite.test/api/orders/orders"
  ./scripts/down.sh
  TAG=1.0.0 ./scripts/up.sh
  curl -s http://shoplite.test/api/orders/orders
  echo ""
  echo '```'
  echo ""

  echo "## Test 9: Only --purge deletes data"
  echo '```bash'
  echo "./scripts/down.sh --purge && TAG=1.0.0 ./scripts/up.sh && curl -s http://shoplite.test/api/orders/orders && curl -s http://shoplite.test/api/inventory/stock/1"
  ./scripts/down.sh --purge
  TAG=1.0.0 ./scripts/up.sh
  curl -s http://shoplite.test/api/orders/orders
  echo ""
  curl -s http://shoplite.test/api/inventory/stock/1
  echo ""
  echo '```'
  echo ""

  echo "## Test 10: Only the domain is served"
  echo '```bash'
  echo "curl -v http://127.0.0.1"
  curl -v http://127.0.0.1 2>&1 || true
  echo "curl -v -H 'Host: other.test' http://127.0.0.1"
  curl -v -H 'Host: other.test' http://127.0.0.1 2>&1 || true
  echo '```'
} > "$OUT"

echo "Saved $OUT"
