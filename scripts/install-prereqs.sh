#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
  echo "Missing required command: sudo" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports apt-based Linux environments only." >&2
  echo "Please install docker, terraform, kubectl, k3d, mkcert, and libnss3-tools manually." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg libnss3-tools

if ! command -v kubectl >/dev/null 2>&1; then
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
fi

if ! command -v terraform >/dev/null 2>&1; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
fi

if ! command -v mkcert >/dev/null 2>&1; then
  sudo apt-get install -y mkcert
fi

if ! command -v kubectl >/dev/null 2>&1 || ! command -v terraform >/dev/null 2>&1; then
  sudo apt-get update
fi

if ! command -v kubectl >/dev/null 2>&1; then
  sudo apt-get install -y kubectl
fi

if ! command -v terraform >/dev/null 2>&1; then
  sudo apt-get install -y terraform
fi

if ! command -v k3d >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Please install Docker Desktop or Docker Engine manually, then rerun bootstrap." >&2
  exit 1
fi

mkcert -install

echo "Local prerequisites installed."
