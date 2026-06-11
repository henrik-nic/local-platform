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

if docker ps -a --format '{{.Names}}' | grep -qx "k3d-${REGISTRY_NAME}"; then
  docker start "k3d-${REGISTRY_NAME}" >/dev/null || true
fi

if k3d cluster list 2>/dev/null | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  k3d cluster start "${CLUSTER_NAME}" || true
fi

echo "Started local platform containers."
