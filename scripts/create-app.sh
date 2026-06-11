#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="${ROOT_DIR}/gitops/templates/app"
APP_NAME="${1:-}"

if [ -z "${APP_NAME}" ]; then
  echo "Usage: $0 <app-name>" >&2
  echo "Example: $0 app1" >&2
  exit 1
fi

if [[ ! "${APP_NAME}" =~ ^[a-z0-9-]+$ ]]; then
  echo "App name must use lowercase letters, digits, and hyphens only." >&2
  exit 1
fi

APP_DIR="${ROOT_DIR}/gitops/apps/${APP_NAME}"

if [ -e "${APP_DIR}" ]; then
  echo "App already exists: ${APP_DIR}" >&2
  exit 1
fi

mkdir -p \
  "${APP_DIR}/base" \
  "${APP_DIR}/overlays/dev" \
  "${APP_DIR}/overlays/test" \
  "${APP_DIR}/overlays/stage" \
  "${APP_DIR}/overlays/prod"

for template in deployment ingress kustomization service; do
  sed "s/__APP_NAME__/${APP_NAME}/g" \
    "${TEMPLATE_DIR}/base/${template}.yaml.tpl" \
    > "${APP_DIR}/base/${template}.yaml"
done

for env_name in dev test stage prod; do
  sed "s/__APP_NAME__/${APP_NAME}/g" \
    "${TEMPLATE_DIR}/overlays/${env_name}/kustomization.yaml.tpl" \
    > "${APP_DIR}/overlays/${env_name}/kustomization.yaml"

  case "${env_name}" in
    dev) namespace="local-dev" ;;
    test) namespace="local-test" ;;
    stage) namespace="local-staging" ;;
    prod) namespace="local-prod-sim" ;;
  esac

  sed \
    -e "s/__APP_NAME__/${APP_NAME}/g" \
    -e "s/__ENV_NAME__/${env_name}/g" \
    -e "s/__NAMESPACE__/${namespace}/g" \
    "${TEMPLATE_DIR}/application.yaml.tpl" \
    > "${ROOT_DIR}/gitops/environments/${env_name}/${APP_NAME}-application.yaml"
done

echo "Created app scaffold for ${APP_NAME}"
echo "App manifests: ${APP_DIR}"
echo "Argo CD applications: ${ROOT_DIR}/gitops/environments/{dev,test,stage,prod}/${APP_NAME}-application.yaml"
