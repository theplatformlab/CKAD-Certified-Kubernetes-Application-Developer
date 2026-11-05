#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# CKAD Practice Cluster Setup
# ═══════════════════════════════════════════════════════════════
# Creates a local Kubernetes cluster for CKAD practice using kind, minikube, or k3d.
# Usage: bash scripts/create-cluster.sh [kind|minikube|k3d]
# Default: kind
# Override the pinned Kubernetes version with K8S_VERSION=v1.x.y.
#
# Source: https://github.com/techwithmohamed/CKAD-Certified-Kubernetes-Application-Developer

set -euo pipefail

CLUSTER_NAME="ckad-practice"
K8S_VERSION="${K8S_VERSION:-v1.37.0}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

TOOL="${1:-kind}"

check_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}Error: '$1' is not installed.${NC}"
    echo ""
    case "$1" in
      kind)
        echo "Install kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        echo "  # Linux (x86_64)"
        echo "  curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64"
        echo "  chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind"
        echo "  brew install kind          # macOS"
        echo "  choco install kind         # Windows"
        ;;
      minikube)
        echo "Install minikube: https://minikube.sigs.k8s.io/docs/start/"
        echo "  # Linux (x86_64)"
        echo "  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
        echo "  sudo install minikube-linux-amd64 /usr/local/bin/minikube"
        echo "  brew install minikube      # macOS"
        echo "  choco install minikube     # Windows"
        ;;
      k3d)
        echo "Install k3d: https://k3d.io/#installation"
        echo "  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash   # Linux/macOS"
        echo "  brew install k3d           # macOS"
        echo "  choco install k3d          # Windows"
        ;;
    esac
    exit 1
  fi
}

check_tool kubectl

case "$TOOL" in
  kind)
    check_tool kind

    echo -e "${BOLD}Creating kind cluster '${CLUSTER_NAME}'...${NC}"

    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
      echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists. Delete it first with:${NC}"
      echo "  kind delete cluster --name ${CLUSTER_NAME}"
      exit 1
    fi

    # Create cluster with a config that supports NetworkPolicy testing
    cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --image "kindest/node:${K8S_VERSION}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
    ;;

  minikube)
    check_tool minikube

    echo -e "${BOLD}Creating minikube cluster '${CLUSTER_NAME}'...${NC}"

    if minikube status -p "${CLUSTER_NAME}" &>/dev/null; then
      echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists. Delete it first with:${NC}"
      echo "  minikube delete -p ${CLUSTER_NAME}"
      exit 1
    fi

    minikube start \
      -p "${CLUSTER_NAME}" \
      --kubernetes-version="${K8S_VERSION}" \
      --nodes=3 \
      --cpus=2 \
      --memory=2048
    ;;

  k3d)
    check_tool k3d

    echo -e "${BOLD}Creating k3d cluster '${CLUSTER_NAME}'...${NC}"

    if k3d cluster list 2>/dev/null | grep -q "${CLUSTER_NAME}"; then
      echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists. Delete it first with:${NC}"
      echo "  k3d cluster delete ${CLUSTER_NAME}"
      exit 1
    fi

    if ! k3d cluster create "${CLUSTER_NAME}" \
      --agents 2 \
      --image "rancher/k3s:${K8S_VERSION}-k3s1"; then
      echo -e "${RED}Could not create the pinned K3s image for Kubernetes ${K8S_VERSION}.${NC}"
      echo "Check that this K3s release is available, or retry with a supported version:"
      echo "  K8S_VERSION=v1.x.y bash scripts/create-cluster.sh k3d"
      exit 1
    fi
    ;;

  *)
    echo -e "${RED}Unknown tool: ${TOOL}${NC}"
    echo "Usage: bash scripts/create-cluster.sh [kind|minikube|k3d]"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Cluster '${CLUSTER_NAME}' is ready!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
kubectl cluster-info --context "kind-${CLUSTER_NAME}" 2>/dev/null || kubectl cluster-info
kubectl get nodes
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Run exam setup:   source scripts/exam-setup.sh"
echo "  2. Start practicing: bash exercises/01-pod-basics/verify.sh"
echo "  3. Take the quiz:    bash scripts/quiz.sh"
echo "  4. Mock exam:        bash scripts/mock-exam.sh"
echo ""
echo -e "${BOLD}Delete cluster when done:${NC}"
case "$TOOL" in
  kind)    echo "  kind delete cluster --name ${CLUSTER_NAME}" ;;
  minikube) echo "  minikube delete -p ${CLUSTER_NAME}" ;;
  k3d)     echo "  k3d cluster delete ${CLUSTER_NAME}" ;;
esac
