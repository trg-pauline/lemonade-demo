# Grafana Setup

This directory contains Grafana deployment configuration for the Lemonade Stand demo.

## Deployment

### 1. Create the Prometheus token secret

Run the setup script **before** installing the Helm chart. This creates the bearer token
secret that the Grafana datasource needs to authenticate with Prometheus/Thanos:

```bash
./grafana/setup-datasource.sh
```

The script will:
- Ensure the target namespace exists
- Create a service account token from `prometheus-k8s` in `openshift-monitoring`
- Store the token in a Kubernetes secret (`grafana-sa-token`)

### 2. Deploy Grafana via Helm

```bash
helm install lemonade-grafana ./grafana --namespace lemonade-demo
```

The Helm chart deploys:
- Grafana instance (with OAuth proxy)
- `GrafanaDatasource` CRD (Prometheus, auto-configured from the token secret)
- `GrafanaDashboard` CRD (Lemonade Stand Guardrails Metrics)
- RBAC for cluster monitoring access

### 3. Access Grafana

Get the Grafana URL:
```bash
oc get route grafana-route -n lemonade-demo -o jsonpath='{.spec.host}'
```

**Default credentials:** `admin` / `grafana`

## Token Refresh

The Prometheus token expires after 24 hours. To refresh, re-run the setup script:

```bash
./grafana/setup-datasource.sh
```

The Grafana Operator will automatically pick up the updated secret on its next
resync cycle (every 5 minutes). No Helm upgrade is needed.

## Dashboards

The Grafana instance includes:
- **Lemonade Stand Guardrails Metrics** - Shows guardrail detections and request metrics

Dashboards are automatically deployed and managed via the `GrafanaDashboard` CRD.
