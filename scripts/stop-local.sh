#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-local}"
REGISTRY_NAME="${REGISTRY_NAME:-local-registry}"

for cmd in docker k3d; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

if k3d cluster list 2>/dev/null | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  k3d cluster stop "${CLUSTER_NAME}" || true
fi

if docker ps -a --format '{{.Names}}' | grep -qx "k3d-${REGISTRY_NAME}"; then
  docker stop "k3d-${REGISTRY_NAME}" >/dev/null || true
fi

echo "Stopped local platform containers without deleting state."
