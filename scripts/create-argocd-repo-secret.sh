#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_PATH="${ROOT_DIR}/.secrets/argocd/nicpublicdocs_deploy_key"
REPO_URL="${1:-git@github.com:henrik-nic/nicPublicdocs.git}"
SECRET_NAME="${2:-nicpublicdocs-repo}"

if [ ! -f "${KEY_PATH}" ]; then
  echo "Missing private key: ${KEY_PATH}" >&2
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
  name: nicpublicdocs
  type: git
  url: ${REPO_URL}
  sshPrivateKey: |
$(sed 's/^/    /' "${KEY_PATH}")
EOF
