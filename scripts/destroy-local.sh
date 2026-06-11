#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform/environments/local"
CLUSTER_NAME="${CLUSTER_NAME:-local}"
REGISTRY_NAME="${REGISTRY_NAME:-local-registry}"

for cmd in docker terraform k3d; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

if [ -d "${TF_DIR}" ]; then
  cd "${TF_DIR}"
  terraform init
  terraform destroy -auto-approve || true
fi

if k3d cluster list 2>/dev/null | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  k3d cluster delete "${CLUSTER_NAME}"
fi

if k3d registry list 2>/dev/null | awk '{print $1}' | grep -qx "${REGISTRY_NAME}"; then
  k3d registry delete "${REGISTRY_NAME}"
fi
