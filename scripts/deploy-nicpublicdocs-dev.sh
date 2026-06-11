#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY_DIR="${ROOT_DIR}/gitops/apps/nicpublicdocs/overlays/dev"

for cmd in docker kubectl; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

"${ROOT_DIR}/scripts/build-nicpublicdocs-image.sh" dev
kubectl apply -k "${OVERLAY_DIR}"

echo
echo "nicPublicdocs dev deployed."
echo "URL: http://nicpublicdocs-dev.localtest.me:8080"
