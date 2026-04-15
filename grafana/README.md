# Grafana Setup

This directory contains Grafana deployment configuration for the Lemonade Stand demo.

## Deployment

### 1. Deploy Grafana via Helm

```bash
helm install lemonade-grafana ./grafana -n lemonade-demo
```

### 2. Setup Datasource

After Grafana is deployed, run the setup script to create the Prometheus datasource:

```bash
./grafana/setup-datasource.sh
```

The script will:
- Wait for Grafana pod to be ready
- Create a service account token from `prometheus-k8s` in `openshift-monitoring`
- Store the token in a secret (`grafana-sa-token`)
- Create the Prometheus datasource via Grafana API

### 3. Access Grafana

Get the Grafana URL:
```bash
oc get route grafana-route -n lemonade-demo -o jsonpath='{.spec.host}'
```

**Default credentials:** `admin` / `grafana`

## Token Refresh

The Prometheus token expires after 24 hours. To refresh:

```bash
./grafana/setup-datasource.sh
```

Or update the token duration in the script (change `--duration=24h` to a longer value).

## Dashboards

The Grafana instance includes:
- **Lemonade Stand Guardrails Metrics** - Shows guardrail detections and request metrics

Dashboards are automatically deployed via the Helm chart.
