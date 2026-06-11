apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: local-test

resources:
  - ../../base

patches:
  - target:
      kind: Ingress
      name: __APP_NAME__
    patch: |-
      - op: replace
        path: /spec/rules/0/host
        value: __APP_NAME__-test.localtest.me

images:
  - name: k3d-local-registry:5000/__APP_NAME__
    newTag: test
