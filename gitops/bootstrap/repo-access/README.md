# Repo Access

This folder holds tracked templates for connecting Argo CD to private Git repositories.

Do not commit private keys into this repository.

## Recommended layout

- Local private keys: `local-platform/.secrets/argocd/`
- Tracked manifest templates: `local-platform/gitops/bootstrap/repo-access/`

For multiple repositories, keep one key and one Argo CD repository secret per repo.

Recommended naming pattern:

- Key file: `.secrets/argocd/<repo-name>_deploy_key`
- Secret name: `<repo-name>-repo`
- Argo CD repo name: `<repo-name>`

## GitHub deploy key flow

1. Generate a dedicated read-only SSH key pair for Argo CD.
2. Add the public key to the target GitHub repository as a deploy key.
3. Create the Argo CD repository secret from the local private key.

The secret template in this folder shows the required shape, but the private key value should be injected locally, not committed.

## Example for many repos

If you manage 10 repositories, repeat the same pattern 10 times:

```text
.secrets/argocd/
  app1_deploy_key
  app2_deploy_key
  app3_deploy_key
  ...
```

Example secret generation:

```bash
cd local-platform
./scripts/create-argocd-repo-secret.sh git@github.com:your-org/app1.git app1-repo app1 ./.secrets/argocd/app1_deploy_key
./scripts/create-argocd-repo-secret.sh git@github.com:your-org/app2.git app2-repo app2 ./.secrets/argocd/app2_deploy_key
```
