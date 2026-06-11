#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="$(mktemp -d)"
trap 'rm -rf "$CERT_DIR"' EXIT

declare -a ENV_NAMES=("dev" "test" "stage" "prod")
declare -a NAMESPACES=("local-dev" "local-test" "local-staging" "local-prod-sim")
declare -a HOSTS=(
  "nicpublicdocs-dev.localtest.me"
  "nicpublicdocs-test.localtest.me"
  "nicpublicdocs-stage.localtest.me"
  "nicpublicdocs-prod.localtest.me"
)

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
  host="${HOSTS[$i]}"
  secret_name="nicpublicdocs-${env_name}-tls"

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

echo "Applied nicPublicdocs TLS secrets for dev/test/stage/prod."
