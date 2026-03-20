#!/bin/bash
# ==============================================================================
# Deploy Kong Ingress Controller to EKS
# ==============================================================================
# Prerequisites:
#   - kubectl configured for EKS cluster
#   - helm installed
#
# Usage:
#   ./k8s/deploy-kong.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Step 1: Add Kong Helm repo ==="
helm repo add kong https://charts.konghq.com
helm repo update

echo ""
echo "=== Step 2: Install Kong Ingress Controller ==="
helm upgrade --install kong kong/kong \
  -n kong --create-namespace \
  -f "$SCRIPT_DIR/kong-values.yaml" \
  --version 2.47.0 \
  --wait --timeout 300s

echo ""
echo "=== Step 3: Wait for Kong proxy LoadBalancer ==="
echo "Waiting for external IP/hostname..."
LB_HOST=""
for i in $(seq 1 30); do
  LB_HOST=$(kubectl get svc kong-kong-proxy -n kong -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -n "$LB_HOST" ]; then
    echo "Kong LoadBalancer: $LB_HOST"
    break
  fi
  echo "  Waiting... ($i/30)"
  sleep 10
done

if [ -z "$LB_HOST" ]; then
  echo "ERROR: LoadBalancer hostname not available after 5 minutes"
  exit 1
fi

echo ""
echo "=== Step 4: Apply Ingress routes ==="
kubectl apply -f "$SCRIPT_DIR/kong-ingress.yaml"

echo ""
echo "=== Done ==="
echo ""
echo "Kong Ingress Controller deployed."
echo "LoadBalancer: $LB_HOST"
echo ""
echo "Next steps:"
echo "  1. Point vibevault.live DNS (CNAME) to: $LB_HOST"
echo "  2. Deploy all services via GitHub Actions"
echo "  3. Configure Razorpay webhook URL: https://vibevault.live/payments/webhook/razorpay"
echo "  4. Test: curl https://vibevault.live/auth/signup"
