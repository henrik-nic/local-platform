#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/../nicPublicdocs"
TAG="${1:-dev}"

"${ROOT_DIR}/scripts/build-app-image.sh" nicpublicdocs "${APP_DIR}" "${TAG}"
