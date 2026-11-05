# CKAD Mock Exam — Full Practice Test

**Practice Kubernetes Version:** v1.37
**Duration:** Recommended 2 hours  
**Format:** 15 original practice tasks (mix of easy, medium, hard); points are practice rubric values, not exam percentages.
**Available Practice Points:** 720
**Practice Threshold:** 476/720 points (about 66%); this is not an official exam pass prediction.
**Tip:** Time yourself. Use the exam-strategy.md time budget.

---

## Getting Started

```bash
# 1. Setup aliases (do this FIRST)
alias k=kubectl
alias do='--dry-run=client -o yaml'
export dm='--dry-run=client -o yaml'

# 2. Create exam namespace
kubectl create namespace exam

# 3. Set default ns (optional)
kubectl config set-context --current --namespace=exam

# 4. Start timer (120 min)
```

---

## Questions

### Question 1 (2 min) — Easy: Create Pod

Create a Pod named `simple-pod` in namespace `exam` with:
- Image: `nginx:latest`
- Container port: 80
- Verify it's running

<details>
<summary>Solution</summary>

```bash
kubectl run simple-pod --image=nginx:latest --port=80 -n exam
kubectl get pod -n exam
# Should show: simple-pod 1/1 Running
```

**Points:** 10/10

</details>

---

### Question 2 (2 min) — Easy: Create ConfigMap

Create a ConfigMap named `app-config` in namespace `exam` with:
- Key: `environment` → Value: `production`
- Key: `debug` → Value: `false`

Verify it was created.

<details>
<summary>Solution</summary>

```bash
kubectl create configmap app-config \
  --from-literal=environment=production \
  --from-literal=debug=false \
  -n exam

kubectl get configmap app-config -n exam -o yaml
```

**Points:** 10/10

</details>

---

### Question 3 (5 min) — Medium: Create Deployment + Service

Create a Deployment named `web-app` in namespace `exam` with:
- Image: `nginx`
- Replicas: 3
- Labels: `app: web, tier: frontend`

Expose it via a ClusterIP service named `web-svc` (port 80 → 80).

Verify:
- Deployment shows READY 3/3
- Service has endpoints

<details>
<summary>Solution</summary>

```bash
# Set selector and Pod template labels at creation; Deployment selectors are immutable.
kubectl apply -n exam -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
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
EOF

# Expose service
kubectl expose deployment web-app \
  --port=80 \
  --target-port=80 \
  --name=web-svc \
  -n exam

# Verify
kubectl get deployment web-app -n exam
kubectl get svc web-svc -n exam
kubectl get endpoints web-svc -n exam
```

**Points:** 50/50 (multi-part)

</details>

---

### Question 4 (5 min) — Medium: Fix Service Selector Mismatch

A Deployment named `api-backend` exists with 2 Ready Pods labeled `app: api`. The Service `api-svc` selects `app: backend` and exposes port 8080 to targetPort 80, but has no endpoints.

**Debug and fix it.**

<details>
<summary>Solution</summary>

```bash
# Check service selector
kubectl get svc api-svc -n exam -o jsonpath='{.spec.selector}'

# Check pod labels
kubectl get pod -n exam --show-labels

# Patch only the selector to match the existing Pod labels.
kubectl patch svc api-svc -n exam --type=merge -p '{"spec":{"selector":{"app":"api"}}}'

# Verify
kubectl get endpoints api-svc -n exam
# Should show 2 IPs, not empty
```

**Points:** 40/50 (partial credit for identifying issue without fix)

</details>

---

### Question 5 (5 min) — Medium: RBAC — Create Role + ServiceAccount

Create a ServiceAccount named `reader-sa` in namespace `exam`.  
Create a Role named `pod-reader` that allows `get` and `list` on `pods`.  
Create a RoleBinding to bind them.

Verify the ServiceAccount can list pods.

<details>
<summary>Solution</summary>

```bash
# Create SA
kubectl create serviceaccount reader-sa -n exam

# Create Role
kubectl create role pod-reader \
  --verb=get,list \
  --resource=pods \
  -n exam

# Create RoleBinding
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=exam:reader-sa \
  -n exam

# Verify
kubectl auth can-i list pods \
  --as=system:serviceaccount:exam:reader-sa \
  -n exam
# Should output: yes
```

**Points:** 50/50

</details>

---

### Question 6 (4 min) — Medium: CronJob — Daily Task

Create a CronJob named `daily-task` in namespace `exam` that:
- Runs at 3:00 AM every day (UTC)
- Executes: `echo "Daily backup started" && sleep 5 && echo "Done"`
- Image: `busybox`

Verify it's created.

<details>
<summary>Solution</summary>

```bash
kubectl create cronjob daily-task \
  --image=busybox \
  --schedule="0 3 * * *" \
  -n exam \
  -- /bin/sh -c 'echo "Daily backup started" && sleep 5 && echo "Done"'

# Verify
kubectl get cronjob daily-task -n exam
kubectl describe cronjob daily-task -n exam
```

**Points:** 40/40

</details>

---

### Question 7 (6 min) — Medium-Hard: NetworkPolicy — Allow Specific Traffic

In namespace `exam`:
- Create 2 Pods with labels `tier: frontend` (nginx)
- Create 1 Pod with label `tier: backend` (nginx)

Create a NetworkPolicy named `backend-policy` that:
- Allows ingress traffic to `tier: backend` pods ONLY from `tier: frontend` pods on port 80
- Blocks all other ingress

Verify with `kubectl exec`.

<details>
<summary>Solution</summary>

```bash
# Create frontend pods
kubectl run frontend-1 --image=nginx -l tier=frontend -n exam
kubectl run frontend-2 --image=nginx -l tier=frontend -n exam

# Create backend pod
kubectl run backend-1 --image=nginx -l tier=backend -n exam

# Create NetworkPolicy
kubectl apply -n exam -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: exam
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
EOF

# Verify from a matching and non-matching source using a NetworkPolicy-capable CNI.
kubectl run allowed-client --image=busybox:1.36 -n exam --labels=tier=frontend --command -- sleep 3600
kubectl run blocked-client --image=busybox:1.36 -n exam --command -- sleep 3600
kubectl wait --for=condition=Ready pod/allowed-client pod/blocked-client -n exam --timeout=60s
backend_ip=$(kubectl get pod backend-1 -n exam -o jsonpath='{.status.podIP}')
kubectl exec allowed-client -n exam -- wget -qO- --timeout=3 "http://${backend_ip}:80"
# Expect a response.
kubectl exec blocked-client -n exam -- wget -qO- --timeout=3 "http://${backend_ip}:80"
# Expect timeout/failure.
```

**Points:** 60/60

</details>

---

### Question 8 (7 min) — Hard: Deployment Repair (Image Pull + Probe)

A Deployment named `broken-app` in namespace `exam` has image `nginx:99.99` and a liveness probe on `/health` with `initialDelaySeconds: 1` and `periodSeconds: 1`. Correct the image to `nginx:1.27` and make the liveness probe check `/` with a 10-second initial delay and 5-second period.

Debug and fix both issues.

<details>
<summary>Solution & Debugging Steps</summary>

```bash
# Step 1: Describe pod to see error
kubectl describe pod <pod-name> -n exam | grep -A 5 "Events:"
# Inspect events and identify the image pull and probe configuration errors.

# Step 2: Check logs
kubectl logs <pod-name> -n exam
# Logs may be unavailable until the image is corrected.

# Step 3: Get current image
kubectl get deployment broken-app -n exam -o jsonpath='{.spec.template.spec.containers[0].image}'
# Expected current image: nginx:99.99

# Fix 1: Set correct image
kubectl set image deployment/broken-app \
  nginx=nginx:1.27 \
  -n exam

# Fix 2: Get current probe settings
kubectl get deployment broken-app -n exam -o yaml | grep -A 5 "livenessProbe:"

# Fix 2b: Edit deployment to increase initialDelaySeconds
kubectl edit deployment broken-app -n exam
# Set path to /, initialDelaySeconds to 10, and periodSeconds to 5.

# Verify
kubectl get pod -n exam -l app=broken-app
# Should eventually show: Running (after pulling new image)
```

**Points:** 70/70

</details>

---

### Question 9 (5 min) — Medium: ConfigMap + Pod Env

Create a ConfigMap named `db-config` with:
- `DB_HOST=postgres.default.svc`
- `DB_USERNAME=admin`

Create a Pod named `app-pod` that mounts this ConfigMap as environment variables.

Verify the environment variables are set.

<details>
<summary>Solution</summary>

```bash
# Create ConfigMap
kubectl create configmap db-config \
  --from-literal=DB_HOST=postgres.default.svc \
  --from-literal=DB_USERNAME=admin \
  -n exam

# Create Pod with env from ConfigMap
kubectl apply -n exam -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx
    envFrom:
      - configMapRef:
          name: db-config
EOF

# Verify
kubectl exec app-pod -n exam -- env | grep DB_
# Should show: DB_HOST=postgres.default.svc, DB_USERNAME=admin
```

**Points:** 50/50

</details>

---

### Question 10 (8 min) — Hard: Multi-Step Scenario

In namespace `exam`, complete this workflow:
1. Create Deployment `api-server` (image: nginx, replicas: 2)
2. Expose via Service `api-svc` (port: 8080 → 80)
3. Create NetworkPolicy restricting traffic to port 8080 from pods labeled `allowed: yes`
4. Verify: A pod without label cannot access the service on 8080

<details>
<summary>Solution</summary>

```bash
# Step 1: Create deployment
kubectl create deployment api-server --image=nginx --replicas=2 -n exam

# Step 2: Expose
kubectl expose deployment api-server \
  --port=8080 \
  --target-port=80 \
  --name=api-svc \
  -n exam

# Step 3: Create NetworkPolicy
kubectl apply -n exam -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
spec:
  podSelector:
    matchLabels:
      app: api-server  # Protect the deployment pods
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              allowed: "yes"
      ports:
        - protocol: TCP
          port: 80
EOF

# Step 4: Verify from allowed and blocked clients (requires an enforcing CNI).
kubectl run allowed-pod --image=busybox:1.36 -l allowed=yes -n exam --command -- sleep 3600
kubectl run blocked-pod --image=busybox:1.36 -n exam --command -- sleep 3600
kubectl wait --for=condition=Ready pod/allowed-pod pod/blocked-pod -n exam --timeout=60s
kubectl exec allowed-pod -n exam -- wget -qO- --timeout=3 http://api-svc:8080
# Expect an HTTP response.
kubectl exec blocked-pod -n exam -- wget -qO- --timeout=3 http://api-svc:8080
# Expect timeout/failure.
```

**Points:** 80/80

</details>

---

### Question 11 (6 min) — Medium: Fix Broken Ingress

An Ingress named `web-ingress` in namespace `exam` points to Service `web-svc` on port 80. The Service has selector `app=web` and port 80 targeting 8080. Two Ready Pods are labeled `app=frontend` and listen on 8080. The ingress controller is installed and the ingress class is correct, but external requests receive 503. Fix the cause without changing the Pods.

Debug and fix. (Likely issues: selector mismatch or port mismatch)

<details>
<summary>Solution & Debugging</summary>

```bash
# Step 1: Check Ingress
kubectl get ingress web-ingress -n exam -o yaml

# Step 2: Check service spec
kubectl get svc web-svc -n exam -o yaml

# Step 3: Check endpoints
kubectl get endpoints web-svc -n exam
# If empty: service selector doesn't match pods

# Step 4: Check pod labels
kubectl get pod -n exam --show-labels

# Patch the Service selector to match the Ready Pods.
kubectl patch svc web-svc -n exam --type=merge -p '{"spec":{"selector":{"app":"frontend"}}}'

# Verify:
kubectl get endpoints web-svc -n exam
# Should NOT be empty
```

**Points:** 60/60

</details>

---

### Question 12 (4 min) — Easy: Label and Select

Add labels `app: myapp` and `environment: prod` to all Pods in namespace `exam` that are currently running.

<details>
<summary>Solution</summary>

```bash
# Select Pods by their status phase, then label only the returned Pod names.
kubectl get pods -n exam --field-selector=status.phase=Running -o name |
  xargs -r kubectl label -n exam --overwrite app=myapp environment=prod

# Verify
kubectl get pod -n exam --show-labels | grep myapp
```

**Points:** 30/30

</details>

---

### Question 13 (5 min) — Medium: RBAC Verify + Debug

ServiceAccount `writer-sa` exists in namespace `exam`. Role `writer-role` is bound to it and its first rule grants `create`, `get`, `list`, and `delete` on Deployments, in that order. It should be able to create Deployments but not delete them. Remove only the excessive permission and verify both outcomes.

Verify the permissions. If wrong, fix it.

<details>
<summary>Solution</summary>

```bash
# Check the namespaced role binding
kubectl get rolebinding -n exam -o yaml | grep -A 8 writer-sa

# Check what role is bound
kubectl get role -n exam | grep -i writer

# View role details
kubectl get role writer-role -n exam -o yaml

# Verify permissions
kubectl auth can-i create deployments \
  --as=system:serviceaccount:exam:writer-sa \
  -n exam
# Should be: yes

kubectl auth can-i delete deployments \
  --as=system:serviceaccount:exam:writer-sa \
  -n exam
# Should be: no

# If delete is allowed but shouldn't be:
kubectl edit role writer-role -n exam
# In rules[0].verbs, remove delete and keep create, get, list.
```

**Points:** 50/50

</details>

---

### Question 14 (6 min) — Medium: StatefulSet + Persistent Volume (Intro)

Create a StatefulSet named `database` in namespace `exam` with a headless Service named `database` and one replica:
- Image: `postgres:13`
- Replicas: 1
- Persistent volume claim template named `db-storage` (1Gi, ReadWriteOnce)
- Container volumeMount path: `/var/lib/postgresql/data`
- Provide the required `POSTGRES_PASSWORD` through a Secret and verify the Pod becomes Ready.

<details>
<summary>Solution (Simplified)</summary>

```bash
# Create namespace-local PostgreSQL credentials.
kubectl create secret generic database-secret --from-literal=POSTGRES_PASSWORD='practice-only' -n exam

# Create the governing headless Service first.
kubectl apply -n exam -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  clusterIP: None
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF

# Create StatefulSet
kubectl apply -n exam -f - <<'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
spec:
  serviceName: database
  replicas: 1
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
        image: postgres:13
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: POSTGRES_PASSWORD
        volumeMounts:
        - name: db-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: db-storage
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
EOF

# Verify
kubectl get statefulset database -n exam
kubectl get pvc -n exam
kubectl wait --for=condition=Ready pod/database-0 -n exam --timeout=180s
```

**Points:** 60/60

</details>

---

### Question 15 (7 min) — Medium-Hard: Patch + Annotation

Add an annotation `app.example.com/owner: team-backend` to all Deployments in namespace `exam`.

Patch the `web-app` Deployment to increase replicas to 5 without using `kubectl scale`.

<details>
<summary>Solution</summary>

```bash
# Add annotation to all deployments
kubectl patch deployment --all -n exam -p \
  '{"metadata":{"annotations":{"app.example.com/owner":"team-backend"}}}'

# Patch specific deployment (increase replicas)
kubectl patch deployment web-app -n exam -p \
  '{"spec":{"replicas":5}}'

# Verify
kubectl get deployment web-app -n exam
# Should show: READY 5/5

kubectl get deployment web-app -n exam -o jsonpath='{.metadata.annotations}'
# Should show: app.example.com/owner: team-backend
```

**Points:** 50/50

</details>

---

## Scoring

| Score | Assessment |
|-------|------------|
| 85-100% | Strong result on this practice set; still review missed requirements |
| 66-84% | Review weak domains and retake missed tasks |
| Below 66% | Revisit related exercises, then retake under timed conditions |

These bands describe this practice set only. They are not a prediction of the official exam result.

---

## Post-Exam Review

After completing this mock exam:

1. **Check answers** against solutions above
2. **Identify problem areas** (RBAC? Networking? Deployments?)
3. **Review corresponding pattern file** (patterns/rbac-debug.md, etc.)
4. **Redo the question** the next day
5. **Time yourself** — aim to finish the 15-task set within two hours, leaving time to verify high-value work

Repeat missed tasks until you can complete and verify them reliably under time pressure.

