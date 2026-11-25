#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

AWS_REGION="${AWS_REGION:-ap-south-1}"
ACCOUNT_ID="${ACCOUNT_ID:-333399527674}"
REGISTRY="${REGISTRY:-${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com}"
TAG="${TAG:-$(git rev-parse --short HEAD)}"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

build_and_push() {
  local local_img="$1"
  local repo_name="$2"
  local context_dir="$3"

  docker build --platform linux/amd64 -t "${local_img}:${TAG}" -f "${context_dir}/Dockerfile" "$context_dir"
  docker tag "${local_img}:${TAG}" "${REGISTRY}/${repo_name}:${TAG}"
  docker push "${REGISTRY}/${repo_name}:${TAG}"
}

build_and_push "shop-frontend" "shoplite/frontend" "frontend"
build_and_push "shop-catalog" "shoplite/catalog" "catalog-service"
build_and_push "shop-inventory" "shoplite/inventory" "inventory-service"
build_and_push "shop-orders" "shoplite/orders" "order-service"

echo "Pushed all four images with tag ${TAG} to ${REGISTRY}"
