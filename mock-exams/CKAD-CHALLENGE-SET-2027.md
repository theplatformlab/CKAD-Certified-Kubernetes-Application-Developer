# CKAD Challenge Set — 2027 Practice

Five original, multi-step practice tasks for building speed and checking details. These are written for this repository and are not copied from Reddit, YouTube, or a certification exam.

**Practice baseline:** Kubernetes v1.37. Recheck the official curriculum and exam environment before a 2027 appointment; this version pin keeps local practice repeatable.

**Suggested time:** 75 minutes
**Available practice points:** 50
**Environment:** One disposable cluster; create the namespaces listed below. Task 2 requires a NetworkPolicy-enforcing CNI. The tasks use built-in Kubernetes APIs and do not require an Ingress or Gateway controller.

Do the tasks before opening [the solutions](CKAD-CHALLENGE-SET-2027-SOLUTIONS.md). Award points only for requirements you can demonstrate with cluster state or a command result.

---

## Task 1 — Rollout With Config Refresh (12 points, 18 minutes)

In namespace `challenge-web`:

1. Create ConfigMap `web-settings` with `APP_MODE=staging`.
2. Create Deployment `web` with two replicas of `nginx:1.27`. Its Pod template must have labels `app=web` and `tier=frontend`.
3. Set resource requests to `cpu: 50m`, `memory: 64Mi`; set limits to `cpu: 100m`, `memory: 128Mi`.
4. Add HTTP readiness and liveness probes on port 80, path `/`.
5. Set the rolling update strategy to `maxSurge: 1`, `maxUnavailable: 0`.
6. Load all ConfigMap keys into the container environment. Expose the Deployment as Service `web-svc`, Service port 8080 to container port 80.
7. Verify two Ready replicas and non-empty Service endpoints. Change `APP_MODE` to `production`, trigger the needed rollout, and verify both running containers report `APP_MODE=production`.

**Scoring:** ConfigMap/namespace 2; Deployment labels and replicas 2; resources and probes 3; rollout strategy 1; Service routing 2; refresh and verification 2.

## Task 2 — Isolate API Ingress (12 points, 18 minutes)

In namespace `challenge-net`:

1. Create Deployment `api` with one `nginx:1.27` replica labeled `app=api,tier=backend` and expose it as Service `api-svc` on port 8080 targeting port 80.
2. Create two long-running `curlimages/curl:8.10.1` Pods: `frontend-client` labeled `tier=frontend`, and `untrusted-client` labeled `tier=untrusted`.
3. Create NetworkPolicy `api-guard` selecting only `tier=backend` Pods. Allow ingress only from Pods labeled `tier=frontend` on TCP port 80. Deny other ingress.
4. Verify the frontend client can fetch `http://api-svc:8080/` and the untrusted client cannot.

Use a cluster with a NetworkPolicy-capable CNI. A successfully applied policy on a CNI that does not enforce policies is not a successful connectivity check.

**Scoring:** Deployment and exact labels 2; Service port mapping 2; policy selector and ingress rule 4; working positive test 2; blocked negative test 2.

## Task 3 — Least-Privilege Config Reader (8 points, 10 minutes)

In namespace `challenge-rbac`:

1. Create ServiceAccount `release-bot`.
2. Create Role `config-reader` granting `get`, `list`, and `watch` on ConfigMaps only.
3. Bind the Role to `release-bot` with RoleBinding `release-bot-config`.
4. Verify the ServiceAccount can list ConfigMaps and cannot create ConfigMaps or get Secrets.

**Scoring:** ServiceAccount and namespace 1; exact Role permissions 3; binding subject and role reference 2; all three authorization checks 2.

## Task 4 — Run and Inspect a CronJob (8 points, 12 minutes)

In namespace `challenge-jobs`:

1. Create ConfigMap `job-message` with `MESSAGE=report-ready`.
2. Create CronJob `report` scheduled every five minutes. Its BusyBox container must print the injected message and current date, then exit successfully.
3. Set `concurrencyPolicy: Forbid`, `successfulJobsHistoryLimit: 2`, and `failedJobsHistoryLimit: 1`.
4. Create a one-off Job from the CronJob template so you do not need to wait for the schedule. Verify that the Job completes and its Pod log contains `report-ready`.

**Scoring:** ConfigMap/env injection 2; schedule and command 2; policies/history 2; one-off execution and log verification 2.

## Task 5 — Restricted Pod With Writable Work Area (10 points, 17 minutes)

In namespace `challenge-secure`, create Pod `locked-worker` using `busybox:1.36` that sleeps long enough to inspect. Configure it to:

- Run as non-root UID 10001 and GID 10001, with `fsGroup: 10001`.
- Drop all Linux capabilities, disallow privilege escalation, and use a read-only root filesystem.
- Mount an `emptyDir` volume at `/work`.

Verify the Pod is Ready, `id` shows the configured non-root identity, writing `/work/result.txt` succeeds, and the container security settings match the task.

**Scoring:** Identity and non-root setting 3; capabilities and privilege escalation 2; read-only root filesystem 2; writable volume mount 1; runtime and manifest verification 2.

---

## Review

Record the requirement you missed, the command or observation that revealed it, and the change that fixed it. Retry that task from a clean namespace later. The point total is only this practice set's rubric; it is not an official score or a pass prediction.

[Open solutions](CKAD-CHALLENGE-SET-2027-SOLUTIONS.md)
