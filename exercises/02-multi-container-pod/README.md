# Exercise 2 — Multi-Container Pod (Sidecar) `Medium`

> Related: [Application Design and Build](../../README.md#1-application-design-and-build-20) | [What Changed in v1.35](../../README.md#what-changed-in-v135) | [YAML Skeleton: Pod](../../skeletons/pod.yaml)

Practice the sidecar pattern using shared volumes and the v1.35 native sidecar syntax.

## Task

1. Create namespace `exercise-02`
2. Create a pod named `app-with-sidecar` with:
   - A main container `app` using image `busybox` that writes the date to `/var/log/app.log` every 5 seconds
   - A sidecar container `log-agent` using image `busybox` that tails `/var/log/app.log`
   - Both containers share an `emptyDir` volume mounted at `/var/log`
3. Verify both containers are running and the sidecar is streaming logs

## Hints

- Use `emptyDir: {}` for the shared volume
- Main container command: `sh -c 'while true; do date >> /var/log/app.log; sleep 5; done'`
- Sidecar command: `sh -c 'tail -f /var/log/app.log'`

## Gotchas

- **Both containers must mount the same volume** — if only the main container writes to `/var/log` but the sidecar doesn't mount it, `tail -f` sees nothing
- **`emptyDir` is ephemeral** — data is lost when the pod is deleted; don't confuse it with persistent storage
- **Container names must be unique** within a pod — Kubernetes rejects the spec otherwise
- **Native sidecar (v1.35)** — uses `initContainers` with `restartPolicy: Always`, not `containers`. The ordering matters: the sidecar starts before the main container

## Verify

```bash
kubectl get pod app-with-sidecar -n exercise-02
kubectl logs app-with-sidecar -n exercise-02 -c log-agent
```

## Bonus — Native Sidecar (v1.35)

Recreate using the native sidecar syntax (`restartPolicy: Always` inside `initContainers`).

## Cleanup

```bash
kubectl delete namespace exercise-02
```

<details>
<summary>Solution — Classic Sidecar</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
  namespace: exercise-02
spec:
  containers:
    - name: app
      image: busybox
      command:
        ["sh", "-c", "while true; do date >> /var/log/app.log; sleep 5; done"]
      volumeMounts:
        - name: logs
          mountPath: /var/log
    - name: log-agent
      image: busybox
      command:
        [
          "sh",
          "-c",
          "while [ ! -f /var/log/app.log ]; do sleep 1; done; tail -f /var/log/app.log",
        ]
      volumeMounts:
        - name: logs
          mountPath: /var/log
  volumes:
    - name: logs
      emptyDir: {}
```

</details>

<details>
<summary>Solution — Native Sidecar (v1.35)</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-native-sidecar
  namespace: exercise-02
spec:
  initContainers:
    - name: log-agent
      image: busybox
      restartPolicy: Always
      command:
        [
          "sh",
          "-c",
          "while [ ! -f /var/log/app.log ]; do sleep 1; done; tail -f /var/log/app.log",
        ]
      volumeMounts:
        - name: logs
          mountPath: /var/log
  containers:
    - name: app
      image: busybox
      command:
        ["sh", "-c", "while true; do date >> /var/log/app.log; sleep 5; done"]
      volumeMounts:
        - name: logs
          mountPath: /var/log
  volumes:
    - name: logs
      emptyDir: {}
```

</details>
