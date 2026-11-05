# CKAD Mock Exam 01 — Solutions

**Practice Kubernetes Version:** v1.37
**Available Practice Points:** 63

---

## Pro Tips & Time Savers

### Multiple Solution Approaches
- **Fast path (Imperative)**: Use `kubectl run`, `kubectl create` for quick creation
- **Flexible path (Declarative)**: Use YAML files for complex configs, can reuse across environments
- **Cost**: Declarative takes 2-3 minutes longer but reduces errors on complex Deployments

### Debugging Checklist
When tasks fail, use this sequence:
1. `kubectl get <resource> -n <namespace>` — Status check
2. `kubectl describe pod <name> -n <ns>` — See Events section for root cause
3. `kubectl logs pod <name> -n <ns>` — Check container logs
4. `kubectl logs pod <name> -n <ns> --previous` — Check crashed container logs
5. `kubectl get <resource> -o yaml` — Inspect full spec for typos

### Common Exam Mistakes (Avoid These!)
- ❌ Forgetting `-n <namespace>` in commands (defaults to `default`)
- ❌ Typos in label selectors (e.g., `app=web` vs `app: web` in YAML)
- ❌ Not setting `restartPolicy: Never` for Jobs/CronJobs
- ❌ Missing `selector` field in Deployment YAML (required in v1, not v1beta1)
- ❌ Using `docker build` instead of `podman build` (exam uses Podman)
- ❌ Pod `serviceAccountName` is immutable — must delete & recreate if wrong

### Time Management Tips
- Flag difficult questions (5+ min) and return later
- Use `kubectl explain <resource>` to verify schema (faster than docs)
- Copy working YAML blocks and modify rather than typing from scratch
- Save common templates as local files for paste-and-edit

---

## Question 1 — Pod with Resources and Labels [3 pts]

### ✅ Fast Approach (Imperative — 30 seconds)

```bash
kubectl run web-pod --image=nginx:1.25 \
  --labels=app=web \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=200m,memory=256Mi \
  -n default
```

**Why choose this**: Fastest if you already know all parameters. No YAML editing needed.

### ✅ Flexible Approach (Declarative — 1.5 minutes)

Create `web-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  namespace: default
  labels:
    app: web
spec:
  containers:
  - name: web-pod
    image: nginx:1.25
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
```

Then apply: `kubectl apply -f web-pod.yaml`

**Why choose this**: If unsure about parameters, YAML is self-documenting. Can also export and reuse.

### 🔍 Verification

```bash
kubectl get pod web-pod -o yaml | grep -A 5 "resources\|labels"
# Expected output:
# labels:
#   app: web
# resources:
#   limits:
#     cpu: 200m
#     memory: 256Mi
#   requests:
#     cpu: 100m
#     memory: 128Mi
```

Or more detailed:
```bash
kubectl describe pod web-pod
# Look for "Limits" and "Requests" sections
```

### ⚠️ Common Pitfalls & How to Avoid

| Mistake | What Happens | Fix |
|---------|--------------|-----|
| Forget `-n default` | Goes to `default` namespace (usually OK) but get habit | Always explicit: `-n default` |
| Typo in labels `app=web vs app: web` | In YAML only `:` works; CLI uses `=` | CLI: `key=value`, YAML: `key: value` |
| Set limits lower than requests | Pod creation fails | Always: requests ≤ limits |
| Image doesn't exist | Pod stuck in `ImagePullBackOff` | Verify image exists in registry first |

### 📝 Exam Notes

- **Score criteria**: Full marks if Pod created with all specs, any approach (imperative/declarative)
- **Partial credit**: Missing label → -1 point, Resource mismatch → -1 point
- **Typical time**: 2-3 minutes (including verification)

---

## Question 2 — Multi-Container Pod [4 pts]

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-stack
  namespace: backend
spec:
  initContainers:
  - name: init-db
    image: busybox:1.36
    command: ["sh", "-c", "echo ready > /shared/status"]
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
    volumeMounts:
    - name: shared
      mountPath: /shared
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /shared/app.log; sleep 5; done"]
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
    volumeMounts:
    - name: shared
      mountPath: /shared
  - name: log-agent
    image: busybox:1.36
    command: ["sh", "-c", "while [ ! -f /shared/app.log ]; do sleep 1; done; tail -F /shared/app.log"]
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
    volumeMounts:
    - name: shared
      mountPath: /shared
  volumes:
  - name: shared
    emptyDir: {}
```

**Deployment:**
```bash
kubectl apply -f app-stack.yaml
kubectl get pod app-stack -n backend
kubectl wait --for=condition=Ready pod/app-stack -n backend --timeout=60s
kubectl logs app-stack -n backend -c log-agent --tail=3
# The sidecar should show timestamp lines written by the app container.
```

---

## Question 3 — Pod with Init Container and SecurityContext [5 pts]

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-pod
  namespace: dev
spec:
  securityContext:
    runAsUser: 1000
    fsGroup: 2000
  initContainers:
  - name: prepare
    image: busybox:1.36
    command: ["sh", "-c", "printf '#!/bin/sh\\necho App-started\\n' > /data/startup.sh && chmod +x /data/startup.sh"]
    volumeMounts:
    - name: data
      mountPath: /data
  containers:
  - name: runner
    image: alpine
    command: ["sh", "-c", "/data/startup.sh && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
```

**Verification:**
```bash
kubectl apply -f init-pod.yaml -n dev
kubectl wait --for=condition=ready pod/init-pod -n dev --timeout=30s
kubectl exec init-pod -n dev -- ls -la /data/
# Output should show startup.sh with appropriate permissions
```

---

## Question 4 — Deployment with Rolling Update Strategy [4 pts]

**Solution:**

```bash
kubectl create deployment web-app \
  --image=nginx:1.25 \
  --replicas=3 \
  -n production \
  --dry-run=client -o yaml > deploy.yaml
```

Edit `deploy.yaml` to add:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
```

**Deployment:**
```bash
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web-app -n production
```

---

## Question 5 — Deployment Rolling Update and Rollback [3 pts]

**Solution:**

```bash
# Create deployment
kubectl create deployment api --image=nginx:1.24 --replicas=2 -n apps

# Update image
kubectl set image deployment/api nginx=nginx:1.25 -n apps

# Wait for rollout
kubectl rollout status deployment/api -n apps

# Check history
kubectl rollout history deployment/api -n apps
# Output shows revision 1 and 2

# Rollback
kubectl rollout undo deployment/api -n apps

# Verify
kubectl rollout history deployment/api -n apps
kubectl get deployment api -n apps -o yaml | grep "image:"
# Should show nginx:1.24 again
```

---

## Question 6 — ConfigMap and Pod with Environment Variables [5 pts]

**Solution:**

```bash
# Create namespace (if doesn't exist)
kubectl create namespace config-test

# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=DATABASE_HOST=postgres.default.svc.cluster.local \
  --from-literal=DATABASE_PORT=5432 \
  --from-literal=LOG_LEVEL=debug \
  -n config-test
```

Pod YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: config-test
spec:
  containers:
  - name: app
    image: alpine
    command: ["sleep", "3600"]
    envFrom:
    - configMapRef:
        name: app-config
```

**Verification:**
```bash
kubectl apply -f config-pod.yaml
kubectl exec config-pod -n config-test -- env | grep DATABASE
# Output:
# DATABASE_HOST=postgres.default.svc.cluster.local
# DATABASE_PORT=5432
# LOG_LEVEL=debug
```

---

## Question 7 — Secret and Pod with Volume Mount [4 pts]

**Solution:**

```bash
# Create namespace
kubectl create namespace secrets-ns

# Create Secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=SuperSecret123 \
  -n secrets-ns
```

Pod YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
  namespace: secrets-ns
spec:
  containers:
  - name: app
    image: alpine
    command: ["sleep", "3600"]
    volumeMounts:
    - name: secret-vol
      mountPath: /etc/secrets
  volumes:
  - name: secret-vol
    secret:
      secretName: db-secret
```

**Verification:**
```bash
kubectl apply -f secret-pod.yaml
kubectl exec secret-pod -n secrets-ns -- ls -la /etc/secrets/
# Output shows: username, password files
kubectl exec secret-pod -n secrets-ns -- cat /etc/secrets/username
# Output: admin
```

---

## Question 8 — NetworkPolicy [5 pts]

**Solution:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-traffic
  namespace: network-test
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to: []
    ports:
    - protocol: UDP
      port: 53
```

**Deployment:**
```bash
kubectl apply -f networkpolicy.yaml
kubectl get networkpolicy -n network-test
kubectl describe networkpolicy restrict-traffic -n network-test
```

**Key points:**
- All other ingress/egress traffic is implicitly denied
- DNS egress line allows queries to any destination (empty `to: []`)

---

## Question 9 — Service Exposure [4 pts]

**Solution:**

```bash
# Create Deployment
kubectl create deployment web-server \
  --image=nginx:1.25 \
  --replicas=2 \
  -n web

# Expose as Service
kubectl expose deployment web-server \
  --name=web-service \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP \
  -n web

# Verify
kubectl get svc web-service -n web
kubectl get endpoints web-service -n web
# Should show 2 pod IPs in endpoints
```

---

## Question 10 — Ingress [5 pts]

**Solution:**

First create the Services (if they don't exist):

```bash
kubectl create namespace ingress-test
kubectl create deployment api-svc --image=nginx:1.25 -n ingress-test
kubectl expose deployment api-svc --port=8080 --target-port=80 -n ingress-test

kubectl create deployment web-svc --image=nginx:1.25 -n ingress-test
kubectl expose deployment web-svc --port=80 --target-port=80 -n ingress-test
```

Ingress YAML:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: ingress-test
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-svc
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
```

**Verification:**
```bash
kubectl apply -f ingress.yaml
kubectl get ingress -n ingress-test
kubectl describe ingress app-ingress -n ingress-test
```

---

## Question 11 — RBAC (Role + RoleBinding) [3 pts]

**Solution:**

```bash
# Create namespace
kubectl create namespace dev

# Create ServiceAccount
kubectl create serviceaccount developer -n dev

# Create Role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n dev

# Create RoleBinding
kubectl create rolebinding developer-read-pods \
  --role=pod-reader \
  --serviceaccount=dev:developer \
  -n dev

# Verify permissions
kubectl auth can-i list pods -n dev --as=system:serviceaccount:dev:developer
# Output: yes

# Double-check what they CAN'T do
kubectl auth can-i delete pods -n dev --as=system:serviceaccount:dev:developer
# Output: no
```

---

## Question 12 — ClusterRole + ClusterRoleBinding [4 pts]

**Solution:**

```bash
# Create ClusterRole
kubectl create clusterrole deployment-manager \
  --verb=get,list,create,update,patch \
  --resource=deployments

kubectl create serviceaccount admin -n default --dry-run=client -o yaml | kubectl apply -f -

# Create ClusterRoleBinding
kubectl create clusterrolebinding deploy-admin \
  --clusterrole=deployment-manager \
  --serviceaccount=default:admin

# Verify
kubectl get clusterrole deployment-manager
kubectl get clusterrolebinding deploy-admin
kubectl auth can-i update deployments --as=system:serviceaccount:default:admin
# Output: yes
kubectl auth can-i patch deployments --as=system:serviceaccount:default:admin
# Output: yes
kubectl auth can-i delete deployments --as=system:serviceaccount:default:admin
# Output: no
```

---

## Question 13 — Pod with SecurityContext [5 pts]

**Solution:**

First create a ConfigMap (if needed):

```bash
kubectl create namespace secure
kubectl create configmap app-config --from-literal=key=value -n secure
```

Pod YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: secure
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: alpine
    command: ["sleep", "3600"]
    command: ["sleep", "3600"]
    securityContext:
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: config-vol
      mountPath: /config
  volumes:
  - name: config-vol
    configMap:
      name: app-config
```

**Verification:**
```bash
kubectl apply -f secure-app.yaml
kubectl get pod secure-app -n secure -o yaml | grep -A 10 "securityContext"
```

---

## Question 14 — Pod with Liveness and Readiness Probes [4 pts]

**Solution:**

```bash
kubectl create namespace monitoring
```

Pod YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: health-check
  namespace: monitoring
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 3
```

**Verification:**
```bash
kubectl apply -f health-check.yaml
kubectl describe pod health-check -n monitoring | grep -A 3 "Liveness\|Readiness"
# Output shows probe configuration
```

**Note:** The probes will likely fail since nginx doesn't have `/health` or `/ready` endpoints by default, but the configuration is correct.

---

## Question 15 — StatefulSet with PVC and ConfigMap [5 pts]

**Solution:**

First create ConfigMap:

```bash
kubectl create namespace advanced
kubectl create configmap db-config \
  --from-literal=POSTGRES_DB=mydb \
  --from-literal=POSTGRES_USER=admin \
  -n advanced

kubectl create secret generic db-secret \
  --from-literal=POSTGRES_PASSWORD='change-me-for-practice' \
  -n advanced
```

StatefulSet YAML:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db-app
  namespace: advanced
spec:
  serviceName: db-service
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:15
        envFrom:
        - configMapRef:
            name: db-config
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: POSTGRES_PASSWORD
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast
      resources:
        requests:
          storage: 1Gi
```

Create and apply this headless Service before applying the StatefulSet:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-service
  namespace: advanced
spec:
  clusterIP: None
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
```

**Verification:**
```bash
kubectl apply -f db-service.yaml
kubectl apply -f statefulset.yaml
kubectl get statefulset db-app -n advanced
kubectl get pvc -n advanced
# Should show data-db-app-0, data-db-app-1, data-db-app-2
kubectl wait --for=condition=Ready pod -l app=database -n advanced --timeout=180s
```

---

## Scoring Summary

| Question | Domain | Practice points | Difficulty | Time Est. |
|----------|--------|--------|-----------|-----------|
| 1 | Design & Build | 3 | Easy | 2-3 min |
| 2 | Design & Build | 4 | Medium | 4-5 min |
| 3 | Design & Build | 5 | Hard | 6-8 min |
| 4 | Deployment | 4 | Medium | 4-5 min |
| 5 | Deployment | 3 | Easy | 2-3 min |
| 6 | Configuration | 5 | Medium | 5-6 min |
| 7 | Configuration | 4 | Medium | 4-5 min |
| 8 | Networking | 5 | Hard | 6-8 min |
| 9 | Networking | 4 | Medium | 4-5 min |
| 10 | Networking | 5 | Hard | 6-8 min |
| 11 | RBAC | 3 | Easy | 2-3 min |
| 12 | RBAC | 4 | Medium | 4-5 min |
| 13 | Security | 5 | Hard | 6-8 min |
| 14 | Observability | 4 | Medium | 4-5 min |
| 15 | Design & Build | 5 | Hard | 6-8 min |
| | **Total** | **63** | | |

---

## Bonus: Question 16B — Debugging Pod Image Pull Error [Debugging Skill]

### Problem Diagnosis

When you see `ImagePullBackOff`, the Pod spec has an invalid or inaccessible image. Check events:

```bash
kubectl describe pod image-test -n broken-apps
# Look for Events section:
# - Type: Warning | Reason: Failed | Message: Error response from daemon...
```

### Solution

**Approach 1: Patch (Fastest — 30 seconds)**

```bash
original_uid=$(kubectl get pod image-test -n broken-apps -o jsonpath='{.metadata.uid}')
kubectl patch pod image-test -n broken-apps -p \
  '{"spec":{"containers":[{"name":"app","image":"nginx:1.25"}]}}'

kubectl wait --for=condition=Ready pod/image-test -n broken-apps --timeout=120s
current_uid=$(kubectl get pod image-test -n broken-apps -o jsonpath='{.metadata.uid}')
test "$original_uid" = "$current_uid"
```

### Verification

```bash
kubectl logs image-test -n broken-apps
# No "image not found" errors
```

⚠️ **Common pitfalls**: Misspelled image names, private registry without secrets

---

## Bonus: Question 17B — Debugging ConfigMap Key Mismatch [Debugging Skill]

### Problem Diagnosis

App logs show: `"ConfigMap key DATABASE_URL not found"` → Mismatch between Pod spec and actual ConfigMap keys.

**Step 1: Check actual ConfigMap**

```bash
kubectl get configmap app-config -n app-errors -o yaml
# data:
#   DB_URL: "postgres://..."  # Key exists, not DATABASE_URL!
```

**Step 2: Find the Deployment using it**

```bash
kubectl describe deployment data-processor -n app-errors | grep -A 5 "env:\|valueFrom"
```

### Solution

**Edit Deployment → Fix Key Name**

```bash
kubectl edit deployment data-processor -n app-errors
```

Change:
```yaml
# FROM:
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      key: DATABASE_URL  # ❌ Doesn't exist

# TO:
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      key: DB_URL  # ✅ Matches ConfigMap
```

### Verification

```bash
kubectl rollout status deployment/data-processor -n app-errors
kubectl get pods -n app-errors -l app=data-processor
kubectl logs deployment/data-processor -n app-errors
# Confirm the replacement Pod starts without the missing-key error.
```

---

## Weak Area Review

If you scored below 50% in any domain, review:

- **Design & Build:** kubectl run, pod specs with resources, init containers, security contexts
- **Deployment:** kubectl create deployment, rolling updates, rollback strategies
- **Configuration:** ConfigMaps, Secrets, environment variable injection
- **Networking:** Services, Ingress, NetworkPolicy, DNS
- **RBAC:** ServiceAccounts, Roles, RoleBindings, ClusterRoles
- **Security:** SecurityContexts, capabilities, read-only filesystems
- **Observability:** Probes, logs, resource metrics

---

## Back to Mock Exam

[← Return to MOCK-EXAM-01](MOCK-EXAM-01.md)
