resource "null_resource" "k3d_cluster" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<SCRIPT
set -e

CLUSTER_NAME="${var.cluster_name}"

if ! k3d cluster list | grep -q "^$${CLUSTER_NAME} "; then
  k3d registry create local-registry --port 5001 || true

  k3d cluster create "$${CLUSTER_NAME}" \
    --servers ${var.server_count} \
    --agents ${var.agent_count} \
    --registry-use k3d-local-registry:5000 \
    --port "8080:80@loadbalancer" \
    --port "8443:443@loadbalancer"
fi
SCRIPT
  }
}

resource "null_resource" "namespaces" {
  depends_on = [null_resource.k3d_cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<SCRIPT
set -e

for ns in ${join(" ", var.namespaces)}; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
SCRIPT
  }
}

resource "null_resource" "metallb" {
  depends_on = [null_resource.k3d_cluster]

  triggers = {
    cluster_name      = var.cluster_name
    metallb_version   = var.metallb_version
    metallb_ip_range  = var.metallb_ip_range
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<SCRIPT
set -euo pipefail

CLUSTER_NAME="${var.cluster_name}"
NETWORK_NAME="k3d-$${CLUSTER_NAME}"
CONFIGURED_RANGE="${var.metallb_ip_range}"

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${var.metallb_version}/config/manifests/metallb-native.yaml"
kubectl wait --for=condition=Available deployment/controller -n metallb-system --timeout=300s

if [ -n "$${CONFIGURED_RANGE}" ]; then
  ADDRESS_RANGE="$${CONFIGURED_RANGE}"
else
  SUBNET="$(docker network inspect "$${NETWORK_NAME}" -f '{{(index .IPAM.Config 0).Subnet}}')"
  if [ -z "$${SUBNET}" ]; then
    echo "Could not determine Docker subnet for network $${NETWORK_NAME}" >&2
    exit 1
  fi

  BASE_PREFIX="$(echo "$${SUBNET}" | cut -d/ -f1 | awk -F. '{print $1 "." $2 "." $3}')"
  ADDRESS_RANGE="$${BASE_PREFIX}.240-$${BASE_PREFIX}.250"
fi

cat <<YAML | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: local-platform-pool
  namespace: metallb-system
spec:
  addresses:
    - $${ADDRESS_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: local-platform-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - local-platform-pool
YAML
SCRIPT
  }
}

resource "null_resource" "argocd" {
  depends_on = [null_resource.namespaces, null_resource.metallb]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<SCRIPT
set -e

kubectl apply --server-side -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd \
  --timeout=300s
SCRIPT
  }
}

resource "null_resource" "argocd_tls" {
  depends_on = [null_resource.argocd]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<SCRIPT
set -euo pipefail

CERT_DIR="$(mktemp -d)"
trap 'rm -rf "$${CERT_DIR}"' EXIT

mkcert -install
mkcert \
  -cert-file "$${CERT_DIR}/tls.crt" \
  -key-file "$${CERT_DIR}/tls.key" \
  "${var.argocd_host}"

kubectl create secret tls ${var.argocd_tls_secret_name} \
  -n argocd \
  --cert="$${CERT_DIR}/tls.crt" \
  --key="$${CERT_DIR}/tls.key" \
  --dry-run=client \
  -o yaml | kubectl apply -f -
SCRIPT
  }
}

resource "null_resource" "quotas_and_limits" {
  depends_on = [null_resource.namespaces]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<SCRIPT
set -e

for ns in ${join(" ", var.app_namespaces)}; do
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: $${ns}-quota
  namespace: $${ns}
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "6"
    limits.memory: 8Gi
    pods: "60"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: $${ns}
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 50m
        memory: 128Mi
      default:
        cpu: 500m
        memory: 512Mi
YAML
done
SCRIPT
  }
}

resource "null_resource" "argocd_ingress" {
  depends_on = [null_resource.argocd, null_resource.argocd_tls]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<SCRIPT
set -e

kubectl patch configmap argocd-cmd-params-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd --timeout=300s

cat <<YAML | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - ${var.argocd_host}
      secretName: ${var.argocd_tls_secret_name}
  rules:
    - host: ${var.argocd_host}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
YAML
SCRIPT
  }
}
