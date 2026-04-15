#!/bin/bash
set -e # Exit immediately if any command fails

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${NAMESPACE:-lemonade-demo}"

echo "===================================================="
echo "Grafana Datasource Setup"
echo "Namespace: $NAMESPACE"
echo "===================================================="
echo ""

# ============================================
# Step 1: Wait for Grafana to be ready
# ============================================
echo "▶️  Step 1/3: Waiting for Grafana pod to be ready..."
oc wait --for=condition=ready pod -l app=grafana -n $NAMESPACE --timeout=300s
echo "✅ Grafana ready"
echo ""

# ============================================
# Step 2: Create token-carrying secret
# ============================================
echo "▶️  Step 2/3: Creating Prometheus token-carrying secret..."

# Delete secret if it already exists (for re-runs)
if oc get secret grafana-sa-token -n $NAMESPACE &>/dev/null; then
  echo "Secret already exists. Deleting and recreating..."
  oc delete secret grafana-sa-token -n $NAMESPACE
fi

# Create token and store in secret
TOKEN=$(oc create token prometheus-k8s -n openshift-monitoring --duration=24h)
echo $TOKEN | oc create secret generic grafana-sa-token -n $NAMESPACE --from-literal=token=$TOKEN
echo "✅ Token secret created"
echo ""

# ============================================
# Step 3: Create Prometheus datasource
# ============================================
echo "▶️  Step 3/3: Creating Prometheus datasource..."

# Get Grafana pod
POD=$(oc get pod -n $NAMESPACE -l app=grafana -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD" ]; then
  echo "❌ Error: No Grafana pod found"
  exit 1
fi

# Get token from secret
TOKEN=$(oc get secret grafana-sa-token -n $NAMESPACE -o jsonpath='{.data.token}' | base64 -d)
if [ -z "$TOKEN" ]; then
  echo "❌ Error: Token not found in secret"
  exit 1
fi

# Delete existing datasource if present (for re-runs)
echo "Removing old datasource (if exists)..."
oc exec -n $NAMESPACE $POD -c grafana -- curl -s -X DELETE \
  http://localhost:3000/api/datasources/name/Prometheus \
  -u admin:grafana > /dev/null 2>&1 || true

# Create datasource via Grafana API
oc exec -n $NAMESPACE $POD -c grafana -- curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "https://thanos-querier.openshift-monitoring.svc.cluster.local:9091",
    "access": "proxy",
    "isDefault": true,
    "jsonData": {
      "httpHeaderName1": "Authorization",
      "tlsSkipVerify": true,
      "timeInterval": "5s"
    },
    "secureJsonData": {
      "httpHeaderValue1": "Bearer '"$TOKEN"'"
    }
  }' \
  http://localhost:3000/api/datasources \
  -u admin:grafana > /dev/null

echo "✅ Prometheus datasource created"
echo ""

# ============================================
# Deployment complete
# ============================================
echo "===================================================="
echo "✅ Setup complete!"
echo "===================================================="
echo ""
echo "Access Grafana at:"
ROUTE=$(oc get route grafana-route -n $NAMESPACE -o jsonpath='{.spec.host}')
echo "  https://$ROUTE"
echo ""
echo "Credentials: admin / grafana"
echo ""
