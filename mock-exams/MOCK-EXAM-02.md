# CKAD Mock Exam 02 — 2 Hours, 16 Questions

**Practice Kubernetes Version:** v1.37
**Exam Duration:** 120 minutes  
**Available Practice Points:** 67
**Practice Threshold:** 45/67 points (about 67%); this is not an official exam pass prediction.
**Format:** Performance-based tasks with weighted scoring

---

## Instructions

- Bracketed values are relative practice points, not percentages of the live exam; they add up to 67 points.
- Use only `kubernetes.io/docs`, `kubernetes.io/blog`, and `github.com/kubernetes` for reference
- Use the context stated in each task when it exists. For local practice, use one disposable cluster rather than switching to nonexistent sample contexts.
- Create a task namespace if it does not already exist. Namespace setup does not count toward task time.
- A NetworkPolicy-capable CNI is required for Q8. A Gateway API controller and Gateway are required for Q10. A multi-node cluster is required to exercise Q16's control-plane toleration.
- Time yourself: aim for about 5–8 minutes per task; use the stated budget as a guide, not a guarantee.
- Verify your work before moving to the next question

---

## Question 1 [3 pts] [Design & Build] Easy

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `default`

**Task:**  
Create a Pod named `app-pod` using image `alpine:3.18` with a command that keeps it running for verification. Add environment variables:
- `APP_NAME=MyApp`
- `ENVIRONMENT=production`
- `DEBUG=false`

Verify the environment variables are set when you exec into the pod.

---

## Question 2 [4 pts] [Design & Build] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `dev`

**Task:**  
Create a Pod with a volume that is shared between two containers:
- Main container: `app` using image `nginx:1.25`
- Sidecar container: `log-collector` using image `busybox`
- emptyDir volume named `shared`: mounted at `/data` in both containers
- The app container writes timestamped lines to `/data/access.log` every 3 seconds
- The sidecar follows that file and emits its lines to stdout
- Verify the sidecar logs contain timestamps

---

## Question 3 [5 pts] [Design & Build] Hard

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `staging`

**Task:**  
Create a Pod named `worker-job` with:
- Init container `prepare` using `busybox:1.36` that writes `sample-payload` to `/data/input.txt`
- Main container `processor` using `busybox:1.36` that reads the input, writes `processed: sample-payload` to `/data/output.txt`, then stays running
- Persistent storage: use an existing PVC named `work-pvc` mounted at `/data`
- Add `restartPolicy: OnFailure`

---

## Question 4 [4 pts] [Deployment] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `web`

**Task:**  
Create a Deployment named `frontend` with:
- 3 replicas
- Image: `nginx:1.25`
- Pod labels: `app=frontend`, `version=v2.0`
- Readiness probe: HTTP GET `/`, port 80, initialDelaySeconds=5
- Liveness probe: HTTP GET `/`, port 80, initialDelaySeconds=10

---

## Question 5 [3 pts] [Deployment] Easy

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `production`

**Task:**  
Create a Deployment named `backend` with 2 replicas using image `node:18-alpine`. Update the Rolling Update strategy to have `maxUnavailable=0` and `maxSurge=1`.

---

## Question 6 [5 pts] [Configuration] Hard

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `config`

**Task:**  
1. Create a ConfigMap named `app-settings` with data from file `config.txt` (create a sample file first)
2. Create a Secret named `api-keys` with:
   - `API_KEY=sk-secret123`
   - `API_SECRET=secret-value`
3. Create a Pod named `config-consumer` that:
   - Mounts the ConfigMap as a volume at `/etc/config`
   - Injects Secret keys as environment variables
   - Image: `alpine`

---

## Question 7 [4 pts] [Configuration] Medium

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `database`

**Task:**  
Create a StatefulSet named `postgres` with:
- 3 replicas
- Image: `postgres:15`
- ConfigMap with: `POSTGRES_DB=appdb`, `POSTGRES_USER=dbadmin`
- Secret with: `POSTGRES_PASSWORD=SecurePass123`
- ServiceName: `postgres-service`
- Create the required headless Service and supply `POSTGRES_PASSWORD` from the Secret. Use a 1Gi PVC template so each replica gets its own volume; assume a default StorageClass is available.

---

## Question 8 [5 pts] [Networking] Hard

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `mesh`

**Task:**  
Create a NetworkPolicy named `isolate-backend` that:
- Applies to Pods with label `app=backend`
- Allows ingress from Pods with label `app=frontend` on port 8080
- Allows ingress from Pods with label `app=admin` on port 8080
- Denies all other ingress
- Allows egress to database on port 5432
- Allows DNS egress
- Create one backend Pod listening on 8080, frontend and admin source Pods, and a database Pod listening on 5432, with the corresponding labels above.
- Assume a NetworkPolicy-capable CNI; verify allowed and denied connections from the source Pods.

---

## Question 9 [4 pts] [Networking] Medium

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `api`

**Task:**  
1. Create a Deployment named `api-server` with 2 replicas, image `nginx:1.25`
2. Expose as a NodePort Service named `api-nodeport`:
   - Port: 8080
   - targetPort: 80
   - Specify nodePort: 30001

---

## Question 10 [5 pts] [Networking] Hard

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `routing`

**Task:**  
Assume Gateway `main-gateway` exists in namespace `routing`, and Services `api-backend:8080` and `static-server:80` have ready endpoints.
Create a Gateway API HTTPRoute named `app-route` that:
- Routes traffic for host `myapp.internal`
- Path `/api/v1/*` goes to Service `api-backend` on port 8080
- Path `/static/*` goes to Service `static-server` on port 80
- ParentRef: Gateway named `main-gateway`

---

## Question 11 [3 pts] [RBAC] Easy

**Context:** `kubectl config use-context k8s-cluster1`

**Task:**  
1. Create a ServiceAccount named `app-reader` in namespace `apps`
2. Create a ClusterRole named `pod-lister` that allows `get`, `list`, and `watch` on Pods
3. Create a ClusterRoleBinding named `app-reader-pods` that binds the role to the ServiceAccount

---

## Question 12 [4 pts] [RBAC] Medium

**Context:** `kubectl config use-context k8s-cluster2`

**Task:**  
Create RBAC for a developer who needs to:
- In namespace `dev`: get, list, create, update, delete Deployments
- In namespace `dev`: get, list ConfigMaps
- Outside namespace `dev`: read-only access to Pods (all namespaces)
- Verify allowed and denied verbs, including `watch` on Pods and `delete` on Deployments.

Use a ServiceAccount named `developer` in namespace `dev`.

---

## Question 13 [5 pts] [Security] Hard

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `secure`

**Task:**  
Create a Pod named `restricted` with comprehensive security hardening:
- SecurityContext:
  - runAsNonRoot: true
  - runAsUser: 1001
  - runAsGroup: 3001
  - fsGroup: 2001
  - capabilities: drop ALL
  - allowPrivilegeEscalation: false
  - readOnlyRootFilesystem: true
- Image: `nginxinc/nginx-unprivileged:1.27-alpine`
- memory-backed `emptyDir` mounted at `/tmp`; expose container port 8080 and verify the non-root server responds successfully.

---

## Question 14 [4 pts] [Observability] Medium

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `monitoring`

**Task:**  
1. Create a Pod named `log-generator` that:
   - Image: `busybox`
   - Command: `sh -c 'while true; do echo "$(date): Processing..."; sleep 2; done'`
   - No restartPolicy (default)

2. Get the logs from the last 10 seconds, limited to five lines, and include timestamps:
```bash
kubectl logs log-generator -n monitoring --tail=5
kubectl logs log-generator -n monitoring --timestamps=true
```

---

## Question 15 [4 pts] [Design & Build] Medium

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `jobs`

**Task:**  
Create a CronJob named `backup-job` that:
- Runs every day at 2 AM (02:00)
- Image: `busybox`
- Command: `sh -c 'echo "Backup started at $(date)" && sleep 10 && echo "Backup complete"'`
- `successfulJobsHistoryLimit: 3`
- `failedJobsHistoryLimit: 1`
- `concurrencyPolicy: Forbid`

---

## Question 16 [5 pts] [Design & Build] Hard

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `advanced`

**Task:**  
Create a DaemonSet named `node-monitor` that:
- Runs on every node including control plane
- Image: `busybox`
- Command: `sh -c 'while true; do echo "Node: $(hostname)"; sleep 30; done'`
- toleration for control plane taint
- Add nodeSelector: `kubernetes.io/os=linux`
- Add resource requests: cpu=50m, memory=32Mi

---

---

## Bonus Debugging Scenarios — Not Included in the 67-point Score

### Question 17B [Debugging] — Service with Incorrect Label Selector

**Context:** `kubectl config use-context k8s-cluster2`  
**Namespace:** `prod-svc`

**Task:**  
Service `my-service` exists but has no endpoints. The backend Pods are labeled `tier=application`, but the Service selector is `tier=backend`. Fix the Service selector without touching the Pods.

Verification: `kubectl get endpoints my-service -n prod-svc` should show Pod IPs

---

### Question 18B [Debugging] — StatefulSet with Broken PVC Template

**Context:** `kubectl config use-context k8s-cluster1`  
**Namespace:** `data-ops`

**Task:**  
StatefulSet `data-sync` exists but Pods are stuck in `Pending` state. The `volumeClaimTemplate` requests storage class `expensive` which doesn't exist. Update the StatefulSet to use storage class `standard` (which exists).

Hint: Check `kubectl describe pod` under Events section for PVC pending reason.

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
| 6 | Configuration | 5 | Hard | __/5 |
| 7 | Configuration | 4 | Medium | __/4 |
| 8 | Networking | 5 | Hard | __/5 |
| 9 | Networking | 4 | Medium | __/4 |
| 10 | Networking | 5 | Hard | __/5 |
| 11 | RBAC | 3 | Easy | __/3 |
| 12 | RBAC | 4 | Medium | __/4 |
| 13 | Security | 5 | Hard | __/5 |
| 14 | Observability | 4 | Medium | __/4 |
| 15 | Design & Build | 4 | Medium | __/4 |
| 16 | Design & Build | 5 | Hard | __/5 |
| | **Total** | **67** | | **__/67** |

**Practice threshold:** 45+ points (66% of available points)
**Strong practice result:** 54+ points (80%)
**High practice result:** 63+ points (about 94%)

### Domain Breakdown

| Domain | Questions | Available points | Your Score |
|--------|-----------|--------|-----------|
| Design & Build | 1, 2, 3, 15, 16 | 21 | __/21 |
| Deployment | 4, 5 | 7 | __/7 |
| Configuration | 6, 7 | 9 | __/9 |
| Networking | 8, 9, 10 | 14 | __/14 |
| RBAC | 11, 12 | 7 | __/7 |
| Security | 13 | 5 | __/5 |
| Observability | 14 | 4 | __/4 |

---

## See Also

- [CKAD Mock Exam 02 Solutions →](MOCK-EXAM-02-SOLUTIONS.md)
- [CKAD Study Plan](../README.md#ckad-study-plan-4-5-weeks)
- [Mock Exam 01](MOCK-EXAM-01.md)
