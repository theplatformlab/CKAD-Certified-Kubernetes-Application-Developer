# CKAD Mock Exam 01 — 2 Hours, 15 Questions

**Practice Kubernetes Version:** v1.37
**Exam Duration:** 120 minutes  
**Available Practice Points:** 63
**Practice Threshold:** 42/63 points (about 67%); this is not an official exam pass prediction.
**Format:** Performance-based tasks with weighted scoring

---

## Instructions

- Bracketed values are relative practice points, not percentages of the live exam; they add up to 63 points.
- Use only `kubernetes.io/docs`, `kubernetes.io/blog`, and `github.com/kubernetes` for reference
- Use the context stated in each task when it exists. For local practice, use one disposable cluster rather than switching to nonexistent sample contexts.
- Create a task namespace if it does not already exist. Namespace setup does not count toward task time.
- A NetworkPolicy-capable CNI is required for Q8. An Ingress controller/class is required for Q10. A `fast` StorageClass is required for Q15.
- Time yourself: aim for about 5–8 minutes per task; use the stated budget as a guide, not a guarantee.
- Verify your work before moving to the next question

---

## Question 1 [3 pts] [Design & Build] Easy

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `default`

**Task:**  
Create a Pod named `web-pod` using image `nginx:1.25`. Add a label `app=web`. Set CPU request to `100m` and memory request to `128Mi`. Set CPU limit to `200m` and memory limit to `256Mi`.

**Verify:**
```bash
kubectl get pod web-pod -o yaml | grep -A 5 "resources\|labels"
```

---

## Question 2 [4 pts] [Design & Build] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `backend`

**Task:**  
Create a multi-container Pod named `app-stack` in namespace `backend` with:
- Init container `init-db` using `busybox:1.36` that writes `ready` to `/shared/status` and exits
- Main container `app` using `busybox:1.36` that appends a timestamp to `/shared/app.log` every 5 seconds
- Sidecar `log-agent` using `busybox:1.36` that follows `/shared/app.log`
- One `emptyDir` named `shared`, mounted at `/shared` in all three containers
- CPU request `50m` and memory request `64Mi` for each container

Verify the Pod is Ready and `kubectl logs app-stack -n backend -c log-agent` shows the app timestamps.

---

## Question 3 [5 pts] [Design & Build] Hard

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `dev`

**Task:**  
Create a Pod named `init-pod` in namespace `dev` with:
- Init container `prepare` using image `busybox:1.36` that creates an executable `/data/startup.sh`
- Main container `runner` using image `alpine` that runs the script
- emptyDir volume mounted at `/data`
- SecurityContext: runAsUser 1000, fsGroup 2000

Make the init container run: `printf '#!/bin/sh\\necho App-started\\n' > /data/startup.sh && chmod +x /data/startup.sh`. The runner must execute the script and remain alive for verification.

---

## Question 4 [4 pts] [Deployment] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `production`

**Task:**  
Create a Deployment named `web-app` in namespace `production` with:
- Image: `nginx:1.25`
- Replicas: 3
- Rolling update strategy: `maxSurge=1`, `maxUnavailable=0`
- Pod-template labels: `app=web`, `version=v1` (the Deployment selector must match)

Verify:
```bash
kubectl rollout status deployment/web-app -n production
```

---

## Question 5 [3 pts] [Deployment] Easy

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `apps`

**Task:**  
Create a Deployment named `api` in namespace `apps` with 2 replicas using `nginx:1.24`. Update the image to `nginx:1.25`. Then perform a rollback to the previous version.

Verify the rollout completed, the history contains the update, and the final image is `nginx:1.24`.
```bash
kubectl rollout history deployment/api -n apps
```

---

## Question 6 [5 pts] [Configuration] Medium

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `config-test`

**Task:**  
1. Create a ConfigMap named `app-config` in namespace `config-test` with:
   - `DATABASE_HOST=postgres.default.svc.cluster.local`
   - `DATABASE_PORT=5432`
   - `LOG_LEVEL=debug`

2. Create a Pod named `config-pod` that uses this ConfigMap:
   - All ConfigMap keys should be injected as environment variables
   - Image: `alpine`
   - Command: `sleep 3600`

3. Verify environment variables are set:
```bash
kubectl exec config-pod -n config-test -- env | grep DATABASE
```

---

## Question 7 [4 pts] [Configuration] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `secrets-ns`

**Task:**  
1. Create a Secret named `db-secret` in namespace `secrets-ns` with:
   - `username=admin`
   - `password=SuperSecret123`

2. Create a Pod named `secret-pod` that mounts this Secret as a volume at `/etc/secrets`

3. Verify the Secret is mounted:
```bash
kubectl exec secret-pod -n secrets-ns -- ls -la /etc/secrets/
```

---

## Question 8 [5 pts] [Networking] Hard

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `network-test`

**Task:**  
Create a NetworkPolicy named `restrict-traffic` in namespace `network-test` that:
- Applies to Pods with label `tier=backend`
- Allows ingress from Pods with label `tier=frontend` on TCP port 8080
- Allows egress to Pods with label `tier=database` on TCP port 5432
- Allows DNS egress (UDP port 53 to any)
- Denies all other traffic

---

## Question 9 [4 pts] [Networking] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `web`

**Task:**  
1. Create a Deployment named `web-server` with 2 replicas using `nginx:1.25` in namespace `web`
2. Expose it as a Service named `web-service`:
   - Type: ClusterIP
   - Port: 80
   - targetPort: 80
3. Verify endpoints:
```bash
kubectl get endpoints web-service -n web
```

---

## Question 10 [5 pts] [Networking] Hard

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `ingress-test`

**Task:**  
Create two one-replica Deployments and matching ClusterIP Services in namespace `ingress-test`: `api-svc` listens on Service port 8080 and targets container port 80; `web-svc` listens on port 80 and targets port 80. Then create an Ingress named `app-ingress` that:
- Uses ingressClassName: `nginx`
- Routes `app.example.com/api` to Service `api-svc` on port 8080
- Routes `app.example.com/web` to Service `web-svc` on port 80

---

## Question 11 [3 pts] [RBAC] Easy

**Context:** `kubectl config use-context k8s-cluster1`

**Task:**  
1. Create a ServiceAccount named `developer` in namespace `dev`
2. Create a Role named `pod-reader` that allows `get`, `list`, `watch` on Pods in namespace `dev`
3. Create a RoleBinding named `developer-read-pods` that binds the Role to the ServiceAccount
4. Verify permissions:
```bash
kubectl auth can-i list pods -n dev --as=system:serviceaccount:dev:developer
```

---

## Question 12 [4 pts] [RBAC] Medium

**Context:** `kubectl config use-context k8s-cluster2`

**Task:**  
1. Create a ClusterRole named `deployment-manager` that allows `get`, `list`, `create`, `update`, `patch` on Deployments cluster-wide
2. Create ServiceAccount `admin` in namespace `default` if missing.
3. Create a ClusterRoleBinding named `deploy-admin` that binds this ClusterRole to that ServiceAccount.
4. Verify it can patch Deployments cluster-wide but cannot delete them.

---

## Question 13 [5 pts] [Security] Hard

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `secure`

**Task:**  
Create a Pod named `secure-app` in namespace `secure` with:
- Image: `alpine`
- SecurityContext:
  - runAsUser: 1000
  - runAsGroup: 3000
  - fsGroup: 2000
  - capabilities: drop ALL
  - readOnlyRootFilesystem: true
- A ConfigMap volume mounted at `/config` (mount any existing ConfigMap or create one)
- Run a read-only-safe command long enough to inspect the running Pod; do not rely on the image's default command.

---

## Question 14 [4 pts] [Observability] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `monitoring`

**Task:**  
1. Create a Pod named `health-check` with:
   - Image: `nginx:1.25`
   - Liveness probe: HTTP GET on port 80, path `/`, initialDelaySeconds=10, periodSeconds=5
   - Readiness probe: HTTP GET on port 80, path `/`, initialDelaySeconds=5, periodSeconds=3

2. Verify the probes are configured:
```bash
kubectl describe pod health-check -n monitoring | grep -A 3 "Liveness\|Readiness"
```

---

## Question 15 [5 pts] [Design & Build] Hard

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `advanced`

**Task:**  
Create a StatefulSet named `db-app` in namespace `advanced` with:
- Image: `postgres:15`
- Replicas: 3
- serviceName: `db-service`
- Labels: `app=database`
- Persistent storage: Each pod should have a PVC of size `1Gi` (assume storage class `fast` exists)
- Environment variables from a ConfigMap:
  - `POSTGRES_DB=mydb`
  - `POSTGRES_USER=admin`
- A Secret provides the required `POSTGRES_PASSWORD`; mount one PVC per replica through `volumeClaimTemplates`.
- Create the headless Service named `db-service` required by the StatefulSet.

---

## Question 16+ (Bonus Debugging Scenarios) — For Practice Beyond Exam

### Question 16B [Debugging] — Broken Pod with Image Pull Error

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `broken-apps`

**Task:**  
A Pod named `image-test` in namespace `broken-apps` is stuck in `ImagePullBackOff` state because it references `private-registry/app:v2.0`. Change its image to `nginx:1.25` without deleting the Pod, then verify the same Pod UID becomes Ready.

Troubleshoot and fix without recreating the Pod. Hint: Check pod events with `kubectl describe pod image-test -n broken-apps`

---

### Question 17B [Debugging] — ConfigMap Key Mismatch

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `app-errors`

**Task:**  
Deployment `data-processor` in namespace `app-errors` is not Ready because its container requests ConfigMap key `DATABASE_URL`, while ConfigMap `app-config` contains `DB_URL`. Correct the Deployment's key reference and verify the replacement Pod becomes Ready and logs success. A rollout is expected because environment-variable references are resolved when a container starts.

Verification: `kubectl logs -n app-errors <pod> | grep success`

---

## Scoring Sheet

Copy this table and track your score:

| Q | Domain | Practice points | Difficulty | Score |
|---|--------|-----------------|------------|-------|
| 1 | Design & Build | 3 | Easy | __/3 |
| 2 | Design & Build | 4 | Medium | __/4 |
| 3 | Design & Build | 5 | Hard | __/5 |
| 4 | Deployment | 4 | Medium | __/4 |
| 5 | Deployment | 3 | Easy | __/3 |
| 6 | Configuration | 5 | Medium | __/5 |
| 7 | Configuration | 4 | Medium | __/4 |
| 8 | Networking | 5 | Hard | __/5 |
| 9 | Networking | 4 | Medium | __/4 |
| 10 | Networking | 5 | Hard | __/5 |
| 11 | RBAC | 3 | Easy | __/3 |
| 12 | RBAC | 4 | Medium | __/4 |
| 13 | Security | 5 | Hard | __/5 |
| 14 | Observability | 4 | Medium | __/4 |
| 15 | Design & Build | 5 | Hard | __/5 |
| | **Total** | **63** | | **__/63** |

**Practice threshold:** 42+ points (66% of available points)
**Strong practice result:** 51+ points (80%)
**High practice result:** 59+ points (about 94%)

### Domain Breakdown

| Domain | Questions | Available points | Your Score |
|--------|-----------|--------|-----------|
| Design & Build | 1, 2, 3, 15 | 17 | __/17 |
| Deployment | 4, 5 | 7 | __/7 |
| Configuration | 6, 7 | 9 | __/9 |
| Networking | 8, 9, 10 | 14 | __/14 |
| RBAC | 11, 12 | 7 | __/7 |
| Security | 13 | 5 | __/5 |
| Observability | 14 | 4 | __/4 |

If any domain is <50%, review that domain and redo those questions in 1 week.

---

## See Also

- [CKAD Mock Exam 01 Solutions →](MOCK-EXAM-01-SOLUTIONS.md)
- [CKAD Study Plan](../README.md#ckad-study-plan-4-5-weeks)
- [Docs Pages I Actually Used During the Exam](../README.md#docs-pages-i-actually-used-during-the-exam)
