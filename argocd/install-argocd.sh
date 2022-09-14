#!/usr/bin/env bash

# Check current Kubernetes context is 'docker-desktop'
CURRENT_CONTEXT=$(kubectl config current-context)
if [[ "$CURRENT_CONTEXT" != "docker-desktop" ]]; then
  echo "Current context is not 'docker-desktop' exiting!"
  exit 1
fi

# Create argocd namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Apply latest stable release of ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

printf "Waiting for ArgoCD Server to be ready: "
while [[ $(kubectl get pods -l app.kubernetes.io/name=argocd-server -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
 printf "."
 sleep 1
done

# Read Admin Password from secret
argocd_admin_password=$(kubectl get secret -n argocd argocd-initial-admin-secret -o=jsonpath='{.data.password}' | base64 -d)

echo
echo "ArgoCD Installed - to access UI run"
echo
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo
echo "ArgoCD can then be accessed at https://localhost:8080 - admin / $argocd_admin_password"
echo
kubectl port-forward svc/argocd-server -n argocd 8080:443