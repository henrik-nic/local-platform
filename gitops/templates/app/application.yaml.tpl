apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: __APP_NAME__-__ENV_NAME__
  namespace: argocd
spec:
  project: default
  source:
    # Change this to your own application repository before syncing with Argo CD.
    repoURL: git@github.com:your-org/your-app.git
    targetRevision: main
    path: deploy/overlays/__ENV_NAME__
  destination:
    server: https://kubernetes.default.svc
    namespace: __NAMESPACE__
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
