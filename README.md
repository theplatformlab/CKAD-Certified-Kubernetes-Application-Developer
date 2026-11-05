# CKAD Practice

Original CKAD practice labs and mock exams. All tasks in this repository are independently written; they are not actual certification questions.

**Contents:** [Quick Start](#quick-start) · [Repository Layout](#repository-layout) · [Practice by Domain](#practice-by-domain) · [Local Cluster](#local-cluster) · [Mock Exams](#mock-exams) · [Exam Information](#exam-information)

## Quick Start

For a disposable local cluster, you need Bash, `kubectl`, Docker, and kind. On Windows, run the Bash commands from WSL2 or Git Bash with Docker available.

```bash
# Create the default v1.37 kind practice cluster
bash scripts/create-cluster.sh kind

# Confirm the cluster before applying resources
kubectl config current-context
kubectl get nodes

# Optional aliases for this terminal session
source scripts/exam-setup.sh

# Start the first lab
cd exercises/01-pod-basics
```

The cluster script changes the active Kubernetes context. Use a disposable cluster, never a production or shared context. To remove the default kind cluster when finished:

```bash
kind delete cluster --name ckad-practice
```

Start with [Exercise 01](exercises/01-pod-basics/README.md). Attempt the task, run its verification steps, then open the solution. If the task is already easy, use the domain map below to choose a weaker topic.

## Repository Layout

```text
exercises/       14 labs, timed drills, and multi-step scenarios
mock-exams/      Written mocks, solutions, and challenge set
skeletons/       YAML starting points
patterns/        Short troubleshooting workflows
troubleshooting/ Broken manifests and debugging references
scripts/         Cluster setup, quiz, and mock-exam helpers
```

Questions are kept in the [exercise](exercises/README.md) and [mock exam](mock-exams/README.md) sections. The patterns and troubleshooting files are optional references for when you get stuck.

## Practice by Domain

The weights below are from the [current CNCF CKAD curriculum](https://github.com/cncf/curriculum/tree/main/ckad). Use them to allocate study time, not to predict which tasks will appear.

| Curriculum domain | Weight | Exercises |
|---|---:|---|
| Application Environment, Configuration and Security | 25% | [03](exercises/03-configmap-secret/README.md), [04](exercises/04-rbac/README.md), [10](exercises/10-security-pvc/README.md) |
| Application Design and Build | 20% | [01](exercises/01-pod-basics/README.md), [02](exercises/02-multi-container-pod/README.md), [11](exercises/11-statefulset/README.md), [12](exercises/12-daemonset/README.md), [13](exercises/13-init-containers/README.md), [14](exercises/14-in-place-scaling/README.md) |
| Application Deployment | 20% | [06](exercises/06-rolling-update/README.md), [07](exercises/07-helm/README.md) |
| Services and Networking | 20% | [05](exercises/05-networkpolicy/README.md), [09](exercises/09-ingress-gateway/README.md) |
| Application Observability and Maintenance | 15% | [08](exercises/08-probes/README.md) |

For the full lab list, difficulty labels, and environment notes, open the [exercise catalog](exercises/README.md).

## Local Cluster

The setup script supports kind, Minikube, and k3d. kind is the default. The script pins Kubernetes v1.37 for repeatable practice; override it with `K8S_VERSION=v1.x.y` before running the script if needed.

```bash
bash scripts/create-cluster.sh kind
# or
bash scripts/create-cluster.sh minikube
bash scripts/create-cluster.sh k3d
```

Some labs need extra cluster support: NetworkPolicy enforcement requires a capable CNI; Ingress and Gateway API tasks require the relevant controller/resources; storage tasks may need a StorageClass. Read the exercise notes before starting. The default local cluster will not provide every optional feature.

For a v1.37 API server, use a `kubectl` client within one minor version, per the [Kubernetes version-skew policy](https://kubernetes.io/releases/version-skew-policy/).

## Mock Exams

The written mocks are designed for timed practice. Their task counts, points, and scores are this repository's rubric only; they are not an official blueprint or pass prediction.

| Set | Tasks | Suggested time | Solutions |
|---|---:|---:|---|
| [Mock Exam 01](mock-exams/MOCK-EXAM-01.md) | 15 | 2 hours | [Answers](mock-exams/MOCK-EXAM-01-SOLUTIONS.md) |
| [Mock Exam 02](mock-exams/MOCK-EXAM-02.md) | 16 | 2 hours | [Answers](mock-exams/MOCK-EXAM-02-SOLUTIONS.md) |
| [Full Mock Exam](mock-exams/FULL-MOCK-EXAM.md) | 15 | 2 hours | Inline |
| [Challenge Set 2027](mock-exams/CKAD-CHALLENGE-SET-2027.md) | 5 | 75 minutes | [Answers](mock-exams/CKAD-CHALLENGE-SET-2027-SOLUTIONS.md) |

**Review method:** Mark the exact requirement you missed, find the command or output that exposes the issue, then retry that part later without the solution.

## Exam Information

The Linux Foundation FAQ checked on November 5, 2026 lists a two-hour exam, a 66% passing score, and Kubernetes v1.37. The exam environment tracks recent Kubernetes releases, so these details may change before a 2027 appointment. Check the [official CKAD FAQ](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks), [current CNCF curriculum](https://github.com/cncf/curriculum/tree/main/ckad), and [allowed resources](https://docs.linuxfoundation.org/tc-docs/certification/certification-resources-allowed#certified-kubernetes-administrator-cka-and-certified-kubernetes-application-developer-ckad) close to your exam date.
