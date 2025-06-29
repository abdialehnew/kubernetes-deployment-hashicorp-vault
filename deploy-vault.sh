#!/bin/bash

# Ganti path berikut sesuai dengan file kubeconfig yang kamu gunakan
export KUBECONFIG=/path/to/your/kubeconfig

set -e

NAMESPACE="secret-manager"

echo "=== [1] Cek Namespace ==="
if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
    echo "Namespace '${NAMESPACE}' belum ada, membuat..."
    kubectl create namespace "${NAMESPACE}"
else
    echo "Namespace '${NAMESPACE}' sudah ada, skip create."
fi

echo "=== [2] Apply PVCs ==="
kubectl apply -f vault-data-pvc.yaml -n "${NAMESPACE}"
kubectl apply -f vault-audit-pvc.yaml -n "${NAMESPACE}"
kubectl apply -f vault-rotation-pvc.yaml -n "${NAMESPACE}"

echo "=== [3] Deploy/Upgrade Vault Helm Chart ==="
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

if helm status vault -n "${NAMESPACE}" >/dev/null 2>&1; then
    echo "Vault release sudah ada, melakukan upgrade..."
    helm upgrade vault hashicorp/vault -n "${NAMESPACE}" -f override-values.yaml
else
    echo "Vault release belum ada, melakukan install..."
    helm install vault hashicorp/vault -n "${NAMESPACE}" -f override-values.yaml
fi

echo "=== [DONE] Vault deploy berhasil di namespace '${NAMESPACE}' ==="