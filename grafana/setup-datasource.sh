#!/bin/bash
set -e # Exit immediately if any command fails

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${NAMESPACE:-lemonade-demo}"

echo "===================================================="
echo "Grafana Datasource Token Setup"
echo "Namespace: $NAMESPACE"
echo "===================================================="
echo ""

# ============================================
# Step 1: Ensure namespace exists
# ============================================
echo "Step 1/2: Checking namespace..."
if ! oc get namespace $NAMESPACE &>/dev/null; then
  echo "Creating namespace $NAMESPACE..."
  oc create namespace $NAMESPACE
fi
echo "Namespace ready"
echo ""

# ============================================
# Step 2: Create token-carrying secret
# ============================================
echo "Step 2/2: Creating Prometheus bearer token secret..."

# Delete secret if it already exists (for re-runs / token refresh)
if oc get secret grafana-sa-token -n $NAMESPACE &>/dev/null; then
  echo "Secret already exists. Deleting and recreating..."
  oc delete secret grafana-sa-token -n $NAMESPACE
fi

# Create token and store in secret with "Bearer " prefix
TOKEN=$(oc create token prometheus-k8s -n openshift-monitoring --duration=24h)
oc create secret generic grafana-sa-token -n $NAMESPACE \
  --from-literal=bearer-token="Bearer $TOKEN"
echo "Token secret created"
echo ""

# ============================================
# Done - the GrafanaDatasource CRD picks up the secret automatically
# ============================================
echo "===================================================="
echo "Setup complete!"
echo "===================================================="
echo ""
echo "Next step: install the Grafana Helm chart:"
echo "  helm install lemonade-grafana ./grafana --namespace $NAMESPACE"
echo ""
echo "Note: Token expires after 24 hours. Re-run this script to refresh."
echo ""
