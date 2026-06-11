# local-platform

Portable local platform bootstrap for a multi-environment workflow built around:

- one or many application repos
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
    create-app.sh
    build-app-image.sh
    deploy-app-dev.sh
    apply-app-tls.sh
    install-prereqs.sh
    bootstrap-local.sh
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
- `gitops/templates/app`: reusable templates for scaffolding a new app
- `gitops/apps/<app-name>`: per-app Kubernetes manifests and overlays
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

## Multi-app model

This platform can host as many repos as the user wants.

Recommended pattern:

- One Git repository per app
- One Argo CD repository secret per repo
- One app scaffold under `gitops/apps/<app-name>`
- One Argo CD `Application` manifest per app per environment

For example, with 10 repos you would have:

- `gitops/apps/app1`
- `gitops/apps/app2`
- `gitops/apps/app3`
- ...

Each app can point to a different GitHub repo, branch, and deploy key.

## Add a new app

Create the local Kubernetes and Argo CD scaffold:

```bash
cd local-platform
./scripts/create-app.sh app1
```

That creates:

- `gitops/apps/app1/base`
- `gitops/apps/app1/overlays/dev`
- `gitops/apps/app1/overlays/test`
- `gitops/apps/app1/overlays/stage`
- `gitops/apps/app1/overlays/prod`
- `gitops/environments/dev/app1-application.yaml`
- `gitops/environments/test/app1-application.yaml`
- `gitops/environments/stage/app1-application.yaml`
- `gitops/environments/prod/app1-application.yaml`

Before syncing with Argo CD, change these values in the generated application files:

- `gitops/environments/dev/<app-name>-application.yaml`
- `gitops/environments/test/<app-name>-application.yaml`
- `gitops/environments/stage/<app-name>-application.yaml`
- `gitops/environments/prod/<app-name>-application.yaml`
- `gitops/bootstrap/repo-access/argocd-repo-secret.template.yaml`

What to change:

- Replace `git@github.com:your-org/your-app.git` with your own Git repository URL.
- Keep `targetRevision: main` only if your default branch is actually `main`.
- Replace `REPLACE_WITH_LOCAL_PRIVATE_KEY` with the private deploy key that can read your repo.

If you use the helper script, pass your repo URL explicitly:

```bash
cd local-platform
./scripts/create-argocd-repo-secret.sh git@github.com:your-org/your-app.git
```

The script now refuses to guess a repository, so a new user will not accidentally deploy Henrik's repo.

If you manage multiple repositories, use one Argo CD repository secret per repo. The helper script supports this directly:

```bash
cd local-platform
./scripts/create-argocd-repo-secret.sh git@github.com:your-org/app1.git app1-repo app1 ./.secrets/argocd/app1_deploy_key
./scripts/create-argocd-repo-secret.sh git@github.com:your-org/app2.git app2-repo app2 ./.secrets/argocd/app2_deploy_key
```

Recommended convention when you have many repos:

- Secret name: `<repo-name>-repo`
- Argo CD repo name: `<repo-name>`
- Key path: `.secrets/argocd/<repo-name>_deploy_key`

That makes 10 repos manageable without collisions or hardcoded app names.

## Local build and deploy for any app

To test an app locally, build and push an image into the local k3d registry:

```bash
cd local-platform
./scripts/build-app-image.sh app1 ../app1 dev
```

For the fastest local `dev` flow, deploy directly into the `local-dev` namespace:

```bash
cd local-platform
./scripts/deploy-app-dev.sh app1 ../app1 dev dev
```

Then open:

```text
http://app1-dev.localtest.me:8080
```

To enable trusted HTTPS for an app across all local environments:

```bash
cd local-platform
./scripts/apply-app-tls.sh app1
```

Then the environment URLs become:

- `https://app1-dev.localtest.me:8443`
- `https://app1-test.localtest.me:8443`
- `https://app1-stage.localtest.me:8443`
- `https://app1-prod.localtest.me:8443`

## Environment model

This repo is for platform/bootstrap concerns only.

Use a separate application repo for your public docs, then promote versions with Git tags:

- `dev` can follow `main` or a working commit
- `test` promotes a selected commit or release candidate tag
- `stage` promotes the exact release tag you want to verify
- `prod` promotes the same approved tag

The goal is one app repo, multiple deployed environments, and version promotion through Git references instead of separate code repos.
