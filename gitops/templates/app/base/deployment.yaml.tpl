apiVersion: apps/v1
kind: Deployment
metadata:
  name: __APP_NAME__
spec:
  replicas: 1
  selector:
    matchLabels:
      app: __APP_NAME__
  template:
    metadata:
      labels:
        app: __APP_NAME__
    spec:
      containers:
        - name: __APP_NAME__
          image: k3d-local-registry:5000/__APP_NAME__:dev
          imagePullPolicy: Always
          ports:
            - containerPort: 80
              name: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          livenessProbe:
            httpGet:
              path: /
              port: http
          resources:
            requests:
              cpu: 25m
              memory: 64Mi
            limits:
              cpu: 250m
              memory: 256Mi
