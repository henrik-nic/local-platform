# Repo Access

This folder holds tracked templates for connecting Argo CD to private Git repositories.

Do not commit private keys into this repository.

## Recommended layout

- Local private keys: `local-platform/.secrets/argocd/`
- Tracked manifest templates: `local-platform/gitops/bootstrap/repo-access/`

## GitHub deploy key flow

1. Generate a dedicated read-only SSH key pair for Argo CD.
2. Add the public key to the target GitHub repository as a deploy key.
3. Create the Argo CD repository secret from the local private key.

The secret template in this folder shows the required shape, but the private key value should be injected locally, not committed.
