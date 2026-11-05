# Exercise 14 — In-Place Pod Vertical Scaling `Hard`

> Related: [Application Design and Build](../../README.md#1-application-design-and-build-20) | [Kubernetes resize guide](https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/)

Practice resizing CPU and memory of running pods without recreating the Pod. In-place Pod resize is stable since Kubernetes v1.35 and is available in the v1.37 CKAD practice target.

## Task

1. Create namespace `exercise-14`
2. Create a pod `resize-demo` with image `nginx` and these resources:
   - CPU request: `100m`, CPU limit: `200m`
   - Memory request: `64Mi`, Memory limit: `128Mi`
   - Set `resizePolicy` on the container:
     - CPU: `restartPolicy: NotRequired`
     - Memory: `restartPolicy: RestartContainer`
3. Verify the pod is running with the original resource values
4. Patch the pod to increase CPU request to `200m` and CPU limit to `400m` (in-place, no restart)
5. Verify the CPU was resized without a pod restart (check `kubectl get pod` — RESTARTS should remain 0)
6. Patch the pod to increase memory request to `128Mi` and memory limit to `256Mi`
7. Observe that the container restarts this time (because memory resize policy is `RestartContainer`)

## Hints

- In-place vertical scaling uses the Pod `resize` subresource: `kubectl patch pod ... --subresource=resize`
- The `resizePolicy` field controls whether a resource change requires a container restart
- `NotRequired` = resize without restart (works for CPU)
- `RestartContainer` = container must restart to apply (typically needed for memory)
- Use `kubectl get pod -o jsonpath` to check current resources
- Check `status.conditions` for `PodResizePending` or `PodResizeInProgress`; after completion, compare the desired spec with `status.containerStatuses[*].resources`

## Gotchas

- **Cluster support** — the feature is stable since v1.35 and enabled by default in standard v1.35+ clusters; managed clusters may differ, so confirm control-plane and node support
- **CPU vs Memory behavior** — CPU can resize without restart (`NotRequired`), but memory typically requires `RestartContainer` because the Linux kernel needs to reallocate
- **`resizePolicy` must be set at pod creation** — you can't add it later. If it's missing, the resize is rejected
- **Not all runtimes support it** — containerd 1.6+ supports in-place resize; check your runtime version
- **`status.resize` field** — check this to see if the resize is `InProgress`, `Proposed`, or completed (field disappears when done)

## Verify

```bash
# Desired resources in the Pod spec
kubectl get pod resize-demo -n exercise-14 -o jsonpath='{.spec.containers[0].resources}'

# Resources currently allocated to the running container
kubectl get pod resize-demo -n exercise-14 -o jsonpath='{.status.containerStatuses[0].resources}'

# Check for pending or in-progress resize conditions
kubectl get pod resize-demo -n exercise-14 -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'

# Check restart count (should be 0 after CPU resize, 1 after memory resize)
kubectl get pod resize-demo -n exercise-14 -o jsonpath='{.status.containerStatuses[0].restartCount}'
```

## Cleanup

```bash
kubectl delete namespace exercise-14
```

<details>
<summary>Solution</summary>

```bash
kubectl create namespace exercise-14
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resize-demo
  namespace: exercise-14
spec:
  containers:
  - name: nginx
    image: nginx
    resizePolicy:
    - resourceName: cpu
      restartPolicy: NotRequired
    - resourceName: memory
      restartPolicy: RestartContainer
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 128Mi
```

```bash
kubectl apply -f resize-demo.yaml
kubectl get pod resize-demo -n exercise-14

# Step 1: Resize CPU in-place (no restart)
kubectl patch pod resize-demo -n exercise-14 --subresource=resize --patch '{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"cpu":"200m"},"limits":{"cpu":"400m"}}}]}}'

# Verify CPU changed
kubectl get pod resize-demo -n exercise-14 -o jsonpath='{.spec.containers[0].resources.requests.cpu}'
# 200m

# Verify no restarts
kubectl get pod resize-demo -n exercise-14 -o jsonpath='{.status.containerStatuses[0].restartCount}'
# 0

# Step 2: Resize memory (triggers restart)
kubectl patch pod resize-demo -n exercise-14 --subresource=resize --patch '{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"memory":"128Mi"},"limits":{"memory":"256Mi"}}}]}}'

# Verify restart happened
kubectl get pod resize-demo -n exercise-14 -o jsonpath='{.status.containerStatuses[0].restartCount}'
# 1
```

</details>
