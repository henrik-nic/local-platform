#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_URL="${1:-}"
SECRET_NAME="${2:-}"
REPO_NAME="${3:-}"
KEY_PATH="${4:-}"

if [ -z "${REPO_URL}" ]; then
  echo "Usage: $0 <repo-url> [secret-name] [repo-name] [private-key-path]" >&2
  echo "Example: $0 git@github.com:your-org/app1.git app1-repo app1 ./.secrets/argocd/app1_deploy_key" >&2
  echo "Set your own repository URL before creating the Argo CD repo secret." >&2
  exit 1
fi

if [ -z "${REPO_NAME}" ]; then
  REPO_NAME="$(basename "${REPO_URL}" .git)"
fi

if [ -z "${SECRET_NAME}" ]; then
  SECRET_NAME="${REPO_NAME}-repo"
fi

if [ -z "${KEY_PATH}" ]; then
  KEY_PATH="${ROOT_DIR}/.secrets/argocd/${REPO_NAME}_deploy_key"
fi

if [ ! -f "${KEY_PATH}" ]; then
  echo "Missing private key: ${KEY_PATH}" >&2
  echo "Pass an explicit key path as the fourth argument if you store keys elsewhere." >&2
  exit 1
fi

cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  name: ${REPO_NAME}
  type: git
  url: ${REPO_URL}
  sshPrivateKey: |
$(sed 's/^/    /' "${KEY_PATH}")
EOF
