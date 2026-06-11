apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: __APP_NAME__
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  ingressClassName: traefik
  rules:
    - host: placeholder.localtest.me
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: __APP_NAME__
                port:
                  number: 80
