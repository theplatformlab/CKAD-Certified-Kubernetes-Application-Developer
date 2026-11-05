# CKAD Challenge Set — 2027 Practice Solutions

Use these only after attempting the matching tasks in [CKAD-CHALLENGE-SET-2027.md](CKAD-CHALLENGE-SET-2027.md). Equivalent imperative or declarative solutions are acceptable when they satisfy every requirement.

## Task 1 — Rollout With Config Refresh

```bash
kubectl create namespace challenge-web
kubectl create configmap web-settings -n challenge-web --from-literal=APP_MODE=staging
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: challenge-web
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web
      tier: frontend
  template:
    metadata:
      labels:
        app: web
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - name: http
          containerPort: 80
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
        envFrom:
        - configMapRef:
            name: web-settings
        readinessProbe:
          httpGet:
            path: /
            port: http
        livenessProbe:
          httpGet:
            path: /
            port: http
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: challenge-web
spec:
  selector:
    app: web
    tier: frontend
  ports:
  - name: http
    port: 8080
    targetPort: http
```

Save as `web.yaml`, then apply and verify:

```bash
kubectl apply -f web.yaml
kubectl rollout status deployment/web -n challenge-web
kubectl get pods,svc,endpoints -n challenge-web
kubectl get pods -n challenge-web -l app=web -o wide
```

Update a ConfigMap consumed through environment variables by changing its value and restarting the Deployment. Existing container environments do not change in place.

```bash
kubectl create configmap web-settings -n challenge-web --from-literal=APP_MODE=production --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/web -n challenge-web
kubectl rollout status deployment/web -n challenge-web
kubectl exec deployment/web -n challenge-web -- printenv APP_MODE
```

Expected value: `production`.

## Task 2 — Isolate API Ingress

```bash
kubectl create namespace challenge-net
kubectl create deployment api -n challenge-net --image=nginx:1.27 --replicas=1
kubectl patch deployment api -n challenge-net --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"tier":"backend"}}}}}'
kubectl expose deployment api -n challenge-net --name=api-svc --port=8080 --target-port=80
kubectl run frontend-client -n challenge-net --image=curlimages/curl:8.10.1 --labels=tier=frontend --command -- sh -c 'sleep 3600'
kubectl run untrusted-client -n challenge-net --image=curlimages/curl:8.10.1 --labels=tier=untrusted --command -- sh -c 'sleep 3600'
```

Apply the policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-guard
  namespace: challenge-net
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
```

Save as `api-guard.yaml` and apply. Wait for all three Pods to be Ready, then test:

```bash
kubectl apply -f api-guard.yaml
kubectl wait --for=condition=Ready pod -l app=api -n challenge-net --timeout=90s
kubectl wait --for=condition=Ready pod/frontend-client -n challenge-net --timeout=90s
kubectl wait --for=condition=Ready pod/untrusted-client -n challenge-net --timeout=90s
kubectl exec frontend-client -n challenge-net -- curl --fail --max-time 3 http://api-svc:8080/
kubectl exec untrusted-client -n challenge-net -- curl --fail --max-time 3 http://api-svc:8080/
```

The first request should return nginx content; the second should time out or fail. If both succeed, confirm the cluster's CNI enforces NetworkPolicy. Do not interpret an unenforced policy as a correct negative test.

## Task 3 — Least-Privilege Config Reader

```bash
kubectl create namespace challenge-rbac
kubectl create serviceaccount release-bot -n challenge-rbac
kubectl create role config-reader -n challenge-rbac --verb=get,list,watch --resource=configmaps
kubectl create rolebinding release-bot-config -n challenge-rbac --role=config-reader --serviceaccount=challenge-rbac:release-bot
```

Check the expected allowed and denied actions:

```bash
kubectl auth can-i list configmaps -n challenge-rbac --as=system:serviceaccount:challenge-rbac:release-bot
kubectl auth can-i create configmaps -n challenge-rbac --as=system:serviceaccount:challenge-rbac:release-bot
kubectl auth can-i get secrets -n challenge-rbac --as=system:serviceaccount:challenge-rbac:release-bot
```

Expected results: `yes`, `no`, `no`.

## Task 4 — Run and Inspect a CronJob

```bash
kubectl create namespace challenge-jobs
kubectl create configmap job-message -n challenge-jobs --from-literal=MESSAGE=report-ready
```

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: report
  namespace: challenge-jobs
spec:
  schedule: "*/5 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 2
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: report
            image: busybox:1.36
            command: ["sh", "-c", "echo \"$MESSAGE $(date)\""]
            envFrom:
            - configMapRef:
                name: job-message
```

Save as `report-cronjob.yaml`, apply, and create an immediate Job from the CronJob template:

```bash
kubectl apply -f report-cronjob.yaml
kubectl create job report-now --from=cronjob/report -n challenge-jobs
kubectl wait --for=condition=Complete job/report-now -n challenge-jobs --timeout=90s
kubectl logs job/report-now -n challenge-jobs
```

The log should contain `report-ready`. The one-off Job avoids waiting for the five-minute schedule.

## Task 5 — Restricted Pod With Writable Work Area

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: locked-worker
  namespace: challenge-secure
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    fsGroup: 10001
  containers:
  - name: worker
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: work
      mountPath: /work
  volumes:
  - name: work
    emptyDir: {}
```

Create the namespace and Pod, then verify both the manifest and runtime behavior:

```bash
kubectl create namespace challenge-secure
kubectl apply -f locked-worker.yaml
kubectl wait --for=condition=Ready pod/locked-worker -n challenge-secure --timeout=90s
kubectl exec locked-worker -n challenge-secure -- id
kubectl exec locked-worker -n challenge-secure -- sh -c 'echo verified > /work/result.txt && cat /work/result.txt'
kubectl get pod locked-worker -n challenge-secure -o yaml
```

The write under `/work` should succeed while the root filesystem remains read-only. Check `securityContext` in the Pod spec to verify the remaining settings.
