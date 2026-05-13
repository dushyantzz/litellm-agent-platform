#!/usr/bin/env bash
# Generates a ServiceAccount token kubeconfig for Render deployment.
# Alternative to moving web/worker in-cluster — eliminates static AWS keys
# while keeping Render as the runtime.
#
# Prerequisites: kubectl pointed at the target EKS cluster.
# Usage: CLUSTER_NAME=litellm-agents K8S_NAMESPACE=default bash bin/render-sa-kubeconfig.sh
#
# Output: KUBE_CONFIG_B64 value to paste into Render dashboard.
# After updating KUBE_CONFIG_B64, remove AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY.

set -euo pipefail

CLUSTER="${CLUSTER_NAME:-litellm-agents}"
NS="${K8S_NAMESPACE:-default}"

echo "Applying RBAC manifests..."
kubectl apply -f k8s/rbac-platform.yaml

echo "Waiting for ServiceAccount token to be populated..."
for i in $(seq 1 20); do
  TOKEN=$(kubectl get secret litellm-platform-token -n "$NS" \
    -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null || true)
  CA=$(kubectl get secret litellm-platform-token -n "$NS" \
    -o jsonpath='{.data.ca\.crt}' 2>/dev/null || true)
  [ -n "$TOKEN" ] && [ -n "$CA" ] && break
  echo "  waiting... ($i/20)"
  sleep 2
done

[ -z "$TOKEN" ] && { echo "ERROR: token Secret not populated after 40s. Check: kubectl get secret litellm-platform-token -n $NS"; exit 1; }

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

KUBECONFIG_YAML=$(printf '%s\n' \
  "apiVersion: v1" \
  "kind: Config" \
  "clusters:" \
  "- name: $CLUSTER" \
  "  cluster:" \
  "    server: $SERVER" \
  "    certificate-authority-data: $CA" \
  "users:" \
  "- name: litellm-platform" \
  "  user:" \
  "    token: $TOKEN" \
  "contexts:" \
  "- name: $CLUSTER" \
  "  context:" \
  "    cluster: $CLUSTER" \
  "    user: litellm-platform" \
  "    namespace: $NS" \
  "current-context: $CLUSTER")

B64=$(printf '%s' "$KUBECONFIG_YAML" | base64 | tr -d '\n')

echo ""
echo "================================================================"
echo "Set this environment variable in Render (web + worker services):"
echo "================================================================"
echo ""
echo "KUBE_CONFIG_B64=$B64"
echo ""
echo "Then remove from Render:"
echo "  AWS_ACCESS_KEY_ID"
echo "  AWS_SECRET_ACCESS_KEY"
echo ""
echo "Verify: curl -H 'Authorization: Bearer \$MASTER_KEY' https://your-app.onrender.com/api/v1/health/k8s"
