#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-}"

if [ -z "${APP_NAME}" ]; then
  echo "Usage: $0 <app-name>" >&2
  echo "Example: $0 app1" >&2
  exit 1
fi

CERT_DIR="$(mktemp -d)"
trap 'rm -rf "$CERT_DIR"' EXIT

declare -a ENV_NAMES=("dev" "test" "stage" "prod")
declare -a NAMESPACES=("local-dev" "local-test" "local-staging" "local-prod-sim")

for cmd in mkcert kubectl; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

mkcert -install

for i in "${!ENV_NAMES[@]}"; do
  env_name="${ENV_NAMES[$i]}"
  namespace="${NAMESPACES[$i]}"
  host="${APP_NAME}-${env_name}.localtest.me"
  secret_name="${APP_NAME}-${env_name}-tls"

  mkcert \
    -cert-file "${CERT_DIR}/${env_name}.crt" \
    -key-file "${CERT_DIR}/${env_name}.key" \
    "${host}"

  kubectl create secret tls "${secret_name}" \
    -n "${namespace}" \
    --cert="${CERT_DIR}/${env_name}.crt" \
    --key="${CERT_DIR}/${env_name}.key" \
    --dry-run=client \
    -o yaml | kubectl apply -f -
done

echo "Applied TLS secrets for ${APP_NAME} in dev/test/stage/prod."
