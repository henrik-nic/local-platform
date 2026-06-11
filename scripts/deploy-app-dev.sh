#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${1:-}"
APP_DIR="${2:-}"
TAG="${3:-dev}"
OVERLAY_ENV="${4:-dev}"

if [ -z "${APP_NAME}" ] || [ -z "${APP_DIR}" ]; then
  echo "Usage: $0 <app-name> <app-dir> [tag] [env]" >&2
  echo "Example: $0 app1 ../app1 dev dev" >&2
  exit 1
fi

OVERLAY_DIR="${ROOT_DIR}/gitops/apps/${APP_NAME}/overlays/${OVERLAY_ENV}"

if [ ! -d "${OVERLAY_DIR}" ]; then
  echo "Missing overlay directory: ${OVERLAY_DIR}" >&2
  echo "Run ./scripts/create-app.sh ${APP_NAME} first." >&2
  exit 1
fi

for cmd in kubectl; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

"${ROOT_DIR}/scripts/build-app-image.sh" "${APP_NAME}" "${APP_DIR}" "${TAG}"
kubectl apply -k "${OVERLAY_DIR}"
"${ROOT_DIR}/scripts/verify-app-deployment.sh" "${APP_NAME}" "${OVERLAY_ENV}"

echo
echo "${APP_NAME} ${OVERLAY_ENV} deployed."
echo "URL: http://${APP_NAME}-${OVERLAY_ENV}.localtest.me:8080"
