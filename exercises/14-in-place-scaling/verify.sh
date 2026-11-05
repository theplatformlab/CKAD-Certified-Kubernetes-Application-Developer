#!/usr/bin/env bash
# Verify script for Exercise 14 — In-Place Pod Vertical Scaling
# Usage: bash exercises/14-in-place-scaling/verify.sh

set -euo pipefail

NAMESPACE="exercise-14"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "true" ]; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Verifying Exercise 14 — In-Place Pod Vertical Scaling"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ns_exists=$(kubectl get namespace "$NAMESPACE" --no-headers >/dev/null 2>&1 && echo true || echo false)
check "Namespace '$NAMESPACE' exists" "$ns_exists"

pod_phase=$(kubectl get pod resize-demo -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
check "Pod 'resize-demo' is Running" "$([ "$pod_phase" = "Running" ] && echo true || echo false)"

# Check resizePolicy exists
resize_policy=$(kubectl get pod resize-demo -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].resizePolicy}' 2>/dev/null || echo "")
check "resizePolicy is configured" "$([ -n "$resize_policy" ] && echo true || echo false)"

# Check CPU resources allocated to the running container (not only the desired spec)
cpu_req=$(kubectl get pod resize-demo -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].resources.requests.cpu}' 2>/dev/null || echo "")
check "Allocated CPU request was resized to 200m" "$([ "$cpu_req" = "200m" ] && echo true || echo false)"

# Check CPU limit allocated to the running container
cpu_lim=$(kubectl get pod resize-demo -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].resources.limits.cpu}' 2>/dev/null || echo "")
check "Allocated CPU limit was resized to 400m" "$([ "$cpu_lim" = "400m" ] && echo true || echo false)"

echo ""
echo "Result: $PASS passed, $FAIL failed out of $((PASS + FAIL)) checks"
[ "$FAIL" -eq 0 ] && echo "🎉 Exercise 14 PASSED!" || echo "❌ Exercise 14 has failures — review and retry."
