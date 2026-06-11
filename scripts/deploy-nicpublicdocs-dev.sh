#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/../nicPublicdocs"

"${ROOT_DIR}/scripts/deploy-app-dev.sh" nicpublicdocs "${APP_DIR}" dev dev
