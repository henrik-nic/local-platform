# local-platform

Portable local platform bootstrap for a multi-environment workflow built around:

- one application repo
- Git tags and versions for promotion
- local `dev`, `test`, `stage`, and `prod-sim` namespaces
- Argo CD for GitOps bootstrapping

## Repo layout

```text
local-platform/
  gitops/
    environments/
      dev/
      test/
      stage/
      prod/
  scripts/
    install-prereqs.sh
    bootstrap-local.sh
    apply-nicpublicdocs-tls.sh
    build-nicpublicdocs-image.sh
    deploy-nicpublicdocs-dev.sh
    start-local.sh
    stop-local.sh
    destroy-local.sh
  terraform/
    environments/
      local/
    modules/
      local_platform/
```

## What lives where

- `terraform/modules/local_platform`: reusable local cluster bootstrap logic
- `terraform/environments/local`: the machine-specific entrypoint for your local platform
- `gitops/environments/*`: placeholders for per-environment Argo CD apps/manifests
- `scripts/bootstrap-local.sh`: one-command bootstrap for a fresh machine

## Clone and run on another machine

Prerequisites:

- `terraform`
- `kubectl`
- `k3d`
- `mkcert`
- Docker running locally

Then run:

```bash
cd local-platform
./scripts/install-prereqs.sh
./scripts/bootstrap-local.sh
```

That will initialize Terraform in `terraform/environments/local` and apply the local platform bootstrap.

To pause the local platform without deleting state:

```bash
cd local-platform
./scripts/stop-local.sh
```

To resume it later:

```bash
cd local-platform
./scripts/start-local.sh
```

To tear everything down and reset the local platform:

```bash
cd local-platform
./scripts/destroy-local.sh
```

## Local access without port-forwarding

The local cluster exposes the k3d load balancer on:

- `http://localhost:8080`
- `https://localhost:8443`

Argo CD is published through ingress with a locally trusted certificate at:

- `https://argocd.localtest.me:8443`

`localtest.me` resolves to `127.0.0.1`, so you do not need to edit your hosts file for that hostname.
The bootstrap flow uses `mkcert` to install a local development CA and generate the TLS certificate used by the Argo CD ingress.

## Deploying nicPublicdocs

`nicPublicdocs` is treated as the application source repo and now also contains the Kubernetes deployment manifests that Argo CD can render.

Kustomize overlays live under `nicPublicdocs/deploy/overlays`:

- `deploy/overlays/dev`
- `deploy/overlays/test`
- `deploy/overlays/stage`
- `deploy/overlays/prod`

To test locally, build and push an image into the local k3d registry:

```bash
cd local-platform
./scripts/build-nicpublicdocs-image.sh dev
```

For the fastest local `dev` flow, deploy directly into the `local-dev` namespace:

```bash
cd local-platform
./scripts/deploy-nicpublicdocs-dev.sh
```

That builds the `dev` image, pushes it to the local k3d registry, and applies the `dev` Kustomize overlay.

Then open:

```text
http://nicpublicdocs-dev.localtest.me:8080
```

To enable trusted HTTPS for `dev`, `test`, `stage`, and `prod`, generate and apply local TLS secrets:

```bash
cd local-platform
./scripts/apply-nicpublicdocs-tls.sh
```

Then the environment URLs become:

- `https://nicpublicdocs-dev.localtest.me:8443`
- `https://nicpublicdocs-test.localtest.me:8443`
- `https://nicpublicdocs-stage.localtest.me:8443`
- `https://nicpublicdocs-prod.localtest.me:8443`

Argo CD can still be layered on top afterward once the local `dev` path is confirmed working.

## Environment model

This repo is for platform/bootstrap concerns only.

Use a separate application repo for your public docs, then promote versions with Git tags:

- `dev` can follow `main` or a working commit
- `test` promotes a selected commit or release candidate tag
- `stage` promotes the exact release tag you want to verify
- `prod` promotes the same approved tag

The goal is one app repo, multiple deployed environments, and version promotion through Git references instead of separate code repos.
