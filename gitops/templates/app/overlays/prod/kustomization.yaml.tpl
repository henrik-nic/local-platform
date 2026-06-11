apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: local-prod-sim

resources:
  - ../../base

patches:
  - target:
      kind: Ingress
      name: __APP_NAME__
    patch: |-
      - op: replace
        path: /spec/rules/0/host
        value: __APP_NAME__-prod.localtest.me

images:
  - name: k3d-local-registry:5000/__APP_NAME__
    newTag: prod
