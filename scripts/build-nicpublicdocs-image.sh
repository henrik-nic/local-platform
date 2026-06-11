#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/../nicPublicdocs"
TAG="${1:-dev}"
LOCAL_IMAGE="localhost:5001/nicpublicdocs:${TAG}"
CLUSTER_IMAGE="k3d-local-registry:5000/nicpublicdocs:${TAG}"

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

docker build -t "${LOCAL_IMAGE}" "${APP_DIR}"
docker tag "${LOCAL_IMAGE}" "${CLUSTER_IMAGE}"
docker push "${LOCAL_IMAGE}"

echo "Built ${LOCAL_IMAGE}"
echo "Tagged for cluster as ${CLUSTER_IMAGE}"
echo "Pushed ${LOCAL_IMAGE}"
