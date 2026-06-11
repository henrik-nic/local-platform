#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-}"
DEPLOY_ENV="${2:-dev}"
TIMEOUT="${TIMEOUT:-180s}"
SKIP_HTTP_CHECK="${SKIP_HTTP_CHECK:-0}"

if [ -z "${APP_NAME}" ]; then
  echo "Usage: $0 <app-name> [env]" >&2
  echo "Example: $0 app1 dev" >&2
  exit 1
fi

case "${DEPLOY_ENV}" in
  dev)
    NAMESPACE="local-dev"
    ;;
  test)
    NAMESPACE="local-test"
    ;;
  stage)
    NAMESPACE="local-staging"
    ;;
  prod)
    NAMESPACE="local-prod-sim"
    ;;
  *)
    echo "Unsupported environment: ${DEPLOY_ENV}" >&2
    echo "Expected one of: dev, test, stage, prod" >&2
    exit 1
    ;;
esac

for cmd in kubectl; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

HOST="${APP_NAME}-${DEPLOY_ENV}.localtest.me"
URL="http://${HOST}:8080/"

echo "Verifying deployment for ${APP_NAME} in ${NAMESPACE}..."
kubectl rollout status "deployment/${APP_NAME}" -n "${NAMESPACE}" --timeout="${TIMEOUT}"
kubectl wait --for=condition=available "deployment/${APP_NAME}" -n "${NAMESPACE}" --timeout="${TIMEOUT}"
kubectl get service "${APP_NAME}" -n "${NAMESPACE}" >/dev/null
kubectl get ingress "${APP_NAME}" -n "${NAMESPACE}" >/dev/null

if [ "${SKIP_HTTP_CHECK}" != "1" ] && command -v curl >/dev/null 2>&1; then
  echo "Checking application response at ${URL}..."
  curl --fail --silent --show-error --max-time 10 "${URL}" >/dev/null
elif [ "${SKIP_HTTP_CHECK}" != "1" ]; then
  echo "Skipping HTTP check because curl is not installed."
fi

echo "Verification passed for ${APP_NAME} ${DEPLOY_ENV}."
