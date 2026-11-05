# Exercises

Fourteen original hands-on labs. Try each task before opening its solution. Examples use the repository's v1.37 practice baseline unless noted; this is not a prediction of the exam version.

## Exercises

| # | Exercise | Domain | Difficulty |
|---:|---|---|---|
| 01 | [Pod Basics](01-pod-basics/) | Application Design and Build | Easy |
| 02 | [Multi-Container Pod](02-multi-container-pod/) | Application Design and Build | Medium |
| 03 | [ConfigMap and Secret Injection](03-configmap-secret/) | Environment, Configuration, and Security | Medium |
| 04 | [RBAC](04-rbac/) | Environment, Configuration, and Security | Medium |
| 05 | [NetworkPolicy](05-networkpolicy/) | Services and Networking | Hard |
| 06 | [Deployment Rollout and Rollback](06-rolling-update/) | Application Deployment | Medium |
| 07 | [Helm](07-helm/) | Application Deployment | Medium |
| 08 | [Probes](08-probes/) | Application Observability and Maintenance | Medium |
| 09 | [Ingress and Gateway API](09-ingress-gateway/) | Services and Networking | Hard |
| 10 | [SecurityContext and PVC](10-security-pvc/) | Environment, Configuration, and Security | Hard |
| 11 | [StatefulSet](11-statefulset/) | Application Design and Build | Hard |
| 12 | [DaemonSet](12-daemonset/) | Application Design and Build | Medium |
| 13 | [Init Containers](13-init-containers/) | Application Design and Build | Medium |
| 14 | [In-Place Pod Vertical Scaling](14-in-place-scaling/) | Application Design and Build | Hard |

## Domain Map

Weights are from the [current CNCF CKAD curriculum](https://github.com/cncf/curriculum/tree/main/ckad). Use them to prioritize study time; they do not predict individual exam tasks.

| Curriculum domain | Weight | Exercises |
|---|---:|---|
| Application Environment, Configuration and Security | 25% | 03, 04, 10 |
| Application Design and Build | 20% | 01, 02, 11, 12, 13, 14 |
| Application Deployment | 20% | 06, 07 |
| Services and Networking | 20% | 05, 09 |
| Application Observability and Maintenance | 15% | 08 |

## How to Practice

1. Use a disposable cluster and check the active context.
2. Read the task, build the resources, and verify behavior.
3. Compare with the solution, clean up, and retry anything you missed.

Some labs need a NetworkPolicy-capable CNI, an Ingress/Gateway controller, a StorageClass, or a supported Kubernetes feature. Check the lab notes before starting.

More practice: [Timed drills](timed-exercises.md) · [Multi-step scenarios](multi-step-scenarios.md)