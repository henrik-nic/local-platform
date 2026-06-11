#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${1:-}"
APP_DIR="${2:-}"
TAG="${3:-dev}"
LOCAL_REGISTRY="${LOCAL_REGISTRY:-localhost:5001}"
CLUSTER_REGISTRY="${CLUSTER_REGISTRY:-k3d-local-registry:5000}"

if [ -z "${APP_NAME}" ] || [ -z "${APP_DIR}" ]; then
  echo "Usage: $0 <app-name> <app-dir> [tag]" >&2
  echo "Example: $0 app1 ../app1 dev" >&2
  exit 1
fi

for cmd in docker; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

if [ ! -d "${APP_DIR}" ]; then
  echo "Missing app repo directory: ${APP_DIR}" >&2
  exit 1
fi

LOCAL_IMAGE="${LOCAL_REGISTRY}/${APP_NAME}:${TAG}"
CLUSTER_IMAGE="${CLUSTER_REGISTRY}/${APP_NAME}:${TAG}"

docker build -t "${LOCAL_IMAGE}" "${APP_DIR}"
docker tag "${LOCAL_IMAGE}" "${CLUSTER_IMAGE}"
docker push "${LOCAL_IMAGE}"

echo "Built ${LOCAL_IMAGE}"
echo "Tagged for cluster as ${CLUSTER_IMAGE}"
echo "Pushed ${LOCAL_IMAGE}"
