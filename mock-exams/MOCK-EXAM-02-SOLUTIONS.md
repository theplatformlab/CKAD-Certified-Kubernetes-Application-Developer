# CKAD Mock Exam 02 — Solutions

**Practice Kubernetes Version:** v1.37
**Available Practice Points:** 67
**Difficulty:** Hard (Mix of creation, fixes, and advanced scenarios)

---

## Pro Tips for Exam 02 (Increased Difficulty)

### Advanced Debugging Workflow

For hard questions (marked with 5%):
1. **Always check Events first** — `kubectl describe pod <name>` then look for `Events:` section
2. **Status codes matter** — `Pending` = resource not allocated, `CrashLoopBackOff` = application error
3. **Use jq for complex output** — `kubectl get <resource> -o json | jq `.spec.selector``

### Time Management for Hard Questions

| Status | When to Skip | When to Solve |
|--------|---|---|
| > 8 minutes spent | Flag it! | only if 50+ min left |
| Stuck on debugging | Come back later | might be easy fix |
| Need 3+ edits | Consider reset | declarative approach faster |

### Solution Strategy: Imperative vs Declarative (HARD questions)

For **MOCK-EXAM-02**, most questions require:
- **Declarative > Imperative** — Exam tests editing/fixing YAML more than CLI
- **Default approach**: Write YAML, apply, fix errors iteratively
- **Fast escape**: If debugging takes >3 min, export current state → edit → reapply

### Common Mistakes (Exam 02 Difficulty)

| Mistake | Why | Prevention |
|---------|-----|-----------|
| PVC not bound (Pending) | StorageClass doesn't exist | Check `kubectl get storageclass` first |
| Service has no endpoints | Pod labels don't match selector | Use `kubectl get pods --show-labels` to verify |
| StatefulSet pods stuck | volumeClaimTemplate references wrong SC | `kubectl describe pod` → look for PVC error |
| RBAC violation | Missing verbs in Role | Test with `kubectl auth can-i` before assuming it works |
| Gateway API misconfiguration | HTTPRoute not linking to Gateway | Verify parentRef matches Gateway name/namespace |

---

## Question 1 — Pod with Environment Variables [3 pts]

**Solution:**

```bash
kubectl run app-pod \
  --image=alpine:3.18 \
  --env=APP_NAME=MyApp \
  --env=ENVIRONMENT=production \
  --env=DEBUG=false \
  -n default \
  --command -- sh -c 'env; sleep 3600'
```

Or via YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app-pod
    image: alpine:3.18
    command: ["sh", "-c", "env; sleep 3600"]
    env:
    - name: APP_NAME
      value: MyApp
    - name: ENVIRONMENT
      value: production
    - name: DEBUG
      value: "false"
```

**Verification:**
```bash
kubectl exec app-pod -- env | grep APP_NAME
# Output: APP_NAME=MyApp
kubectl exec app-pod -- env | grep ENVIRONMENT
# Output: ENVIRONMENT=production
```

---

## Question 2 — Pod with Shared Volume (Sidecar Pattern) [4 pts]

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-sidecar
  namespace: dev
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /data/access.log; sleep 3; done"]
    volumeMounts:
    - name: shared
      mountPath: /data
  - name: log-collector
    image: busybox:1.36
    command: ["sh", "-c", "while [ ! -f /data/access.log ]; do sleep 1; done; tail -F /data/access.log"]
    volumeMounts:
    - name: shared
      mountPath: /data
  volumes:
  - name: shared
    emptyDir: {}
```

**Verification:**
```bash
kubectl apply -f app-sidecar.yaml -n dev
kubectl logs app-sidecar -c log-collector -n dev
# Should show timestamp lines written by the app container.
```

---

## Question 3 — Pod with Init Container and PVC [5 pts]

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: worker-job
  namespace: staging
spec:
  restartPolicy: OnFailure
  initContainers:
  - name: prepare
    image: busybox:1.36
    command: ["sh", "-c", "echo sample-payload > /data/input.txt"]
    volumeMounts:
    - name: work
      mountPath: /data
  containers:
  - name: processor
    image: busybox:1.36
    command: ["sh", "-c", "printf 'processed: '; cat /data/input.txt | tr -d '\\n'; echo; printf 'processed: sample-payload\\n' > /data/output.txt; sleep 3600"]
    volumeMounts:
    - name: work
      mountPath: /data
  volumes:
  - name: work
    persistentVolumeClaim:
      claimName: work-pvc
```

**Deployment:**
```bash
kubectl apply -f worker-job.yaml -n staging
```

---

## Question 4 — Deployment with Probes [4 pts]

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        version: v2.0
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
```

**Deployment:**
```bash
kubectl apply -f frontend-deploy.yaml
kubectl rollout status deployment/frontend -n web
```

---

## Question 5 — Deployment with Rolling Update Strategy [3 pts]

**Solution:**

```bash
kubectl create deployment backend \
  --image=node:18-alpine \
  --replicas=2 \
  -n production \
  --dry-run=client -o yaml > backend.yaml
```

Edit to add strategy:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: node
        image: node:18-alpine
```

**Deployment:**
```bash
kubectl apply -f backend.yaml
```

---

## Question 6 — ConfigMap, Secret, Pod with Mixed Mounts [5 pts]

**Solution:**

```bash
# Step 1: Create sample config file
cat > config.txt <<EOF
database_host=postgres.default.svc.cluster.local
database_port=5432
log_level=info
EOF

# Step 2: Create ConfigMap from file
kubectl create configmap app-settings --from-file=config.txt -n config

# Step 3: Create Secret
kubectl create secret generic api-keys \
  --from-literal=API_KEY=sk-secret123 \
  --from-literal=API_SECRET=secret-value \
  -n config
```

Pod YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-consumer
  namespace: config
spec:
  containers:
  - name: app
    image: alpine
    command: ["sleep", "3600"]
    envFrom:
    - secretRef:
        name: api-keys
    volumeMounts:
    - name: config-vol
      mountPath: /etc/config
  volumes:
  - name: config-vol
    configMap:
      name: app-settings
```

**Verification:**
```bash
kubectl apply -f config-consumer.yaml
kubectl exec config-consumer -n config -- env | grep API_KEY
# Output: API_KEY=sk-secret123
kubectl exec config-consumer -n config -- cat /etc/config/config.txt
# Output: database_host=postgres.default.svc.cluster.local...
```

---

## Question 7 — StatefulSet with ConfigMap and Secret [4 pts]

**Solution:**

```bash
kubectl create namespace database

# Create ConfigMap
kubectl create configmap postgres-config \
  --from-literal=POSTGRES_DB=appdb \
  --from-literal=POSTGRES_USER=dbadmin \
  -n database

# Create Secret
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_PASSWORD=SecurePass123 \
  -n database
```

StatefulSet YAML:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: database
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: database
spec:
  serviceName: postgres-service
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        envFrom:
        - configMapRef:
            name: postgres-config
        - secretRef:
            name: postgres-secret
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

**Verification:**
```bash
kubectl apply -f postgres-service.yaml
kubectl apply -f postgres-statefulset.yaml
kubectl get statefulset postgres -n database
kubectl get pods -n database -l app=postgres
kubectl get pvc -n database
kubectl wait --for=condition=Ready pod -l app=postgres -n database --timeout=180s
```

---

## Question 8 — NetworkPolicy with Multiple Sources [5 pts]

**Solution:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-backend
  namespace: mesh
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: admin
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to: []
    ports:
    - protocol: UDP
      port: 53
```

**Key points:**
- Multiple `from` entries are OR'd together
- DNS egress allows any destination (`to: []`)

**Deployment:**
```bash
kubectl run backend --image=busybox:1.36 -n mesh --labels=app=backend --command -- sh -c 'httpd -f -p 8080'
kubectl run frontend --image=busybox:1.36 -n mesh --labels=app=frontend --command -- sleep 3600
kubectl run admin --image=busybox:1.36 -n mesh --labels=app=admin --command -- sleep 3600
kubectl run database --image=busybox:1.36 -n mesh --labels=app=database --command -- sh -c 'nc -lk -p 5432'
kubectl apply -f isolate-backend.yaml
kubectl wait --for=condition=Ready pod/backend pod/frontend pod/admin pod/database -n mesh --timeout=60s
```

---

## Question 9 — NodePort Service [4 pts]

**Solution:**

```bash
# Create Deployment
kubectl create deployment api-server \
  --image=nginx:1.25 \
  --replicas=2 \
  -n api

# Create from the Deployment so the selector matches its Pod labels.
kubectl expose deployment api-server \
  --port=8080 \
  --target-port=80 \
  --type=NodePort \
  --name=api-nodeport \
  -n api \
  --dry-run=client -o yaml > api-nodeport.yaml
# Set spec.ports[0].nodePort to 30001 in api-nodeport.yaml, then apply it.
kubectl apply -f api-nodeport.yaml
```

**Verification:**
```bash
kubectl get svc api-nodeport -n api
# output shows port 8080:30001/TCP
kubectl describe svc api-nodeport -n api
kubectl get endpoints api-nodeport -n api
```

---

## Question 10 — Gateway API HTTPRoute [5 pts]

**Solution:**

Assumes Gateway `main-gateway` exists. If not, create it first:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: routing
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
```

HTTPRoute YAML:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-route
  namespace: routing
spec:
  parentRefs:
  - name: main-gateway
    namespace: routing
  hostnames:
  - myapp.internal
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api/v1
    backendRefs:
    - name: api-backend
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /static
    backendRefs:
    - name: static-server
      port: 80
```

**Verification:**
```bash
kubectl apply -f gateway.yaml
kubectl apply -f httproute.yaml
kubectl get httproute -n routing
```

---

## Question 11 — ClusterRole and ClusterRoleBinding [3 pts]

**Solution:**

```bash
# Create namespace and ServiceAccount
kubectl create namespace apps
kubectl create serviceaccount app-reader -n apps

# Create ClusterRole
kubectl create clusterrole pod-lister \
  --verb=get,list,watch \
  --resource=pods

# Create ClusterRoleBinding
kubectl create clusterrolebinding app-reader-pods \
  --clusterrole=pod-lister \
  --serviceaccount=apps:app-reader

# Verify
kubectl auth can-i list pods --as=system:serviceaccount:apps:app-reader
# Output: yes
kubectl auth can-i watch pods --as=system:serviceaccount:apps:app-reader
# Output: yes
kubectl auth can-i delete pods --as=system:serviceaccount:apps:app-reader
# Output: no
```

---

## Question 12 — Complex RBAC for Developer [4 pts]

**Solution:**

```bash
kubectl create namespace dev
kubectl create serviceaccount developer -n dev

# Role 1: Deployment management in dev namespace
kubectl create role deployment-manager \
  --verb=get,list,create,update,delete,patch \
  --resource=deployments \
  -n dev

# Role 2: ConfigMap read in dev namespace
kubectl create role config-reader \
  --verb=get,list \
  --resource=configmaps \
  -n dev

# RoleBindings for dev namespace
kubectl create rolebinding dev-deploy-role \
  --role=deployment-manager \
  --serviceaccount=dev:developer \
  -n dev

kubectl create rolebinding dev-config-role \
  --role=config-reader \
  --serviceaccount=dev:developer \
  -n dev

# ClusterRole: read-only pod access everywhere
kubectl create clusterrole pod-reader \
  --verb=get,list,watch \
  --resource=pods

# ClusterRoleBinding
kubectl create clusterrolebinding developer-pods \
  --clusterrole=pod-reader \
  --serviceaccount=dev:developer
```

**Verification:**
```bash
kubectl auth can-i update deployments -n dev --as=system:serviceaccount:dev:developer
# Output: yes
kubectl auth can-i delete deployments -n dev --as=system:serviceaccount:dev:developer
# Output: yes
kubectl auth can-i list configmaps -n dev --as=system:serviceaccount:dev:developer
# Output: yes
kubectl auth can-i list pods -n default --as=system:serviceaccount:dev:developer
# Output: yes
kubectl auth can-i create pods -n default --as=system:serviceaccount:dev:developer
# Output: no
kubectl auth can-i watch pods -n default --as=system:serviceaccount:dev:developer
# Output: yes
```

---

## Question 13 — Restrictive SecurityContext with tmpfs [5 pts]

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted
  namespace: secure
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    runAsGroup: 3001
    fsGroup: 2001
  containers:
  - name: nginx
    image: nginxinc/nginx-unprivileged:1.27-alpine
    ports:
    - containerPort: 8080
    securityContext:
      capabilities:
        drop:
        - ALL
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-cache
      mountPath: /var/cache/nginx
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir:
      medium: Memory
  - name: var-cache
    emptyDir: {}
  - name: var-run
    emptyDir: {}
```

**Note:** nginx needs writable temporary directories despite `readOnlyRootFilesystem: true`, hence the emptyDir volumes.

**Verification:**
```bash
kubectl apply -f restricted.yaml -n secure
kubectl get pod restricted -n secure -o yaml | grep -A 15 "securityContext"
kubectl wait --for=condition=Ready pod/restricted -n secure --timeout=90s
kubectl exec restricted -n secure -- wget -qO- http://127.0.0.1:8080/
```

---

## Question 14 — Pod with Continuous Logging [4 pts]

**Solution:**

```bash
kubectl create namespace monitoring

# Create pod
kubectl run log-generator \
  --image=busybox \
  --command -- sh -c 'while true; do echo "$(date): Processing..."; sleep 2; done' \
  -n monitoring
```

Or YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-generator
  namespace: monitoring
spec:
  containers:
  - name: logger
    image: busybox
    command: ["sh", "-c", "while true; do echo \"$(date): Processing...\"; sleep 2; done"]
```

**Verification:**
```bash
kubectl logs log-generator -n monitoring --tail=5
# Shows last 5 lines
kubectl logs log-generator -n monitoring --since=10s --tail=5 --timestamps=true
# At most five timestamped lines from the last ten seconds.
kubectl logs log-generator -n monitoring --timestamps=true
# Shows with timestamps
kubectl logs log-generator -n monitoring -f
# Follow logs in real-time
```

---

## Question 15 — CronJob [4 pts]

**Solution:**

```bash
kubectl create namespace jobs

# Create CronJob
kubectl create cronjob backup-job \
  --image=busybox \
  --schedule="0 2 * * *" \
  -n jobs \
  -- sh -c 'echo "Backup started at $(date)" && sleep 10 && echo "Backup complete"'
```

Or YAML (recommended for fine-tuning):

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
  namespace: jobs
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command: ["sh", "-c", "echo 'Backup started at $(date)' && sleep 10 && echo 'Backup complete'"]
          restartPolicy: OnFailure
```

**Verification:**
```bash
kubectl apply -f backup-job.yaml
kubectl get cronjob -n jobs
kubectl get jobs -n jobs
# Watch jobs being created at 02:00 each day
```

---

## Question 16 — DaemonSet with Tolerations [5 pts]

**Solution:**

```bash
kubectl create namespace advanced
```

DaemonSet YAML:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  namespace: advanced
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: monitor
        image: busybox
        command: ["sh", "-c", "while true; do echo \"Node: $(hostname)\"; sleep 30; done"]
        resources:
          requests:
            cpu: 50m
            memory: 32Mi
```

**Verification:**
```bash
kubectl apply -f node-monitor.yaml
kubectl get daemonset -n advanced
kubectl get pods -n advanced -o wide
# Should show one pod per node (including control plane if toleration works)
```

---

## Scoring Summary

| Question | Domain | Weight | Difficulty | Time Est. |
|----------|--------|--------|-----------|-----------|
| 1 | Design & Build | 3% | Easy | 2-3 min |
| 2 | Design & Build | 4% | Medium | 4-5 min |
| 3 | Design & Build | 5% | Hard | 6-8 min |
| 4 | Deployment | 4% | Medium | 4-5 min |
| 5 | Deployment | 3% | Easy | 2-3 min |
| 6 | Configuration | 5% | Hard | 6-8 min |
| 7 | Configuration | 4% | Medium | 4-5 min |
| 8 | Networking | 5% | Hard | 6-8 min |
| 9 | Networking | 4% | Medium | 4-5 min |
| 10 | Networking | 5% | Hard | 6-8 min |
| 11 | RBAC | 3% | Easy | 2-3 min |
| 12 | RBAC | 4% | Medium | 4-5 min |
| 13 | Security | 5% | Hard | 6-8 min |
| 14 | Observability | 4% | Medium | 4-5 min |
| 15 | Design & Build | 4% | Medium | 4-5 min |
| 16 | Design & Build | 5% | Hard | 6-8 min |

---

## Bonus: Question 17B — Debugging Service with Wrong Label Selector [Debugging Skill]

### Symptom
Service exists but has no endpoints:
```bash
kubectl get endpoints my-service -n prod-svc
# Output: <none>  # Should show Pod IPs!
```

### Root Cause Analysis
```bash
# Step 1: Check Service selector
kubectl get svc my-service -n prod-svc -o yaml | grep -A 3 "selector:"
# Shows: selector: tier: backend

# Step 2: Check actual Pod labels
kubectl get pods -n prod-svc --show-labels
# Shows: tier=application  # Mismatch!
```

### Solution (Without Touching Pods)

```bash
# Edit the Service selector
kubectl patch svc my-service -n prod-svc -p \
  '{"spec":{"selector":{"tier":"application"}}}'

# Verify endpoints appear
kubectl get endpoints my-service -n prod-svc
# Output: <pod-ips> (e.g., 10.0.0.1:80, 10.0.0.2:80)
```

**Alternative with edit:**
```bash
kubectl edit svc my-service -n prod-svc
# Change: tier: backend → tier: application
```

### Verification & Learning

```bash
# Verify connectivity
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://my-service.prod-svc
# Should succeed (not 'Connection refused')

# Debug command to remember
kubectl describe svc my-service -n prod-svc
# Look for 'Endpoints:' section (should show Pod IPs)
```

**Key insight**: Service is just a label matcher — if Pod labels don't match selector, no endpoints!

---

## Bonus: Question 18B — Debugging StatefulSet with Broken PVC Template [Debugging Skill]

### Symptom
Pods in StatefulSet stuck in `Pending` state:

```bash
kubectl get pods -n data-ops -l app=data-sync
# Output: data-sync-0   Pending   0/1   ...
```

### Root Cause Analysis

```bash
# Step 1: Check why Pending
kubectl describe pod data-sync-0 -n data-ops
# Look for Events section:
# Events:
#   Type: Warning 
#   Reason: FailedScheduling
#   Message: Pod didn't trigger scale-up: no StorageClass "expensive"

# Step 2: Verify storage classes available
kubectl get storageclass
# Output: standard, fast  (but NOT "expensive")
```

### Solution

Get the StatefulSet YAML, edit volumeClaimTemplate, reapply:

```bash
kubectl get statefulset data-sync -n data-ops -o yaml > data-sync.yaml
```

Edit `data-sync.yaml`:
```yaml
# FROM:
volumeClaimTemplate:
  spec:
    storageClassName: expensive  # ❌ Doesn't exist!

# TO:
volumeClaimTemplate:
  spec:
    storageClassName: standard  # ✅ Exists!
```

```bash
kubectl delete statefulset data-sync -n data-ops --cascade=orphan
# (orphan keeps existing PVCs to preserve data)

kubectl apply -f data-sync.yaml
# New pods will now use 'standard' StorageClass
```

### Verification

```bash
kubectl get pvc -n data-ops
# Output: data-sync-0  Bound  pvc-xxx  1Gi  standard
#         data-sync-1  Bound  pvc-yyy  1Gi  standard

kubectl get pods data-sync-0 -n data-ops
# Status: Running (not Pending!)
```

**Key insight**: StatefulSets + PVCs are tightly coupled — storage issues cause Pod Pending state, not app issues.

---

## Pro Tip: The Debugging Hierarchy (When to Use What)

1. **Status check** → `kubectl get` (1 sec)
2. **Event inspection** → `kubectl describe` (5 sec)
3. **Configuration review** → `kubectl get -o yaml` (20 sec)
4. **Logs + debugging** → `kubectl logs`, `kubectl exec` (30 sec)
5. **Infrastructure check** → `kubectl get storageclass`, `kubectl get nodes` (10 sec)

Use this order to find 90% of issues in exam. Don't jump to logs before checking Events!

---

## Back to Mock Exam

[← Return to MOCK-EXAM-02](MOCK-EXAM-02.md)
