#!/bin/bash

set -e

echo "Cleaning up Kubernetes resources..."

# Delete ingress
kubectl delete -f kubernetes/ingress.yaml --ignore-not-found=true

# Delete backend
kubectl delete -f kubernetes/backend/backend-service.yaml --ignore-not-found=true
kubectl delete -f kubernetes/backend/backend-deployment.yaml --ignore-not-found=true
kubectl delete -f kubernetes/backend/backend-configmap.yaml --ignore-not-found=true
kubectl delete -f kubernetes/backend/backend-secret.yaml --ignore-not-found=true

# Delete MongoDB
kubectl delete -f kubernetes/mongodb/mongodb-service.yaml --ignore-not-found=true
kubectl delete -f kubernetes/mongodb/mongodb-deployment.yaml --ignore-not-found=true
kubectl delete -f kubernetes/mongodb/mongodb-pvc.yaml --ignore-not-found=true
kubectl delete -f kubernetes/mongodb/mongodb-configmap.yaml --ignore-not-found=true
kubectl delete -f kubernetes/mongodb/mongodb-secret.yaml --ignore-not-found=true

# Delete namespace
kubectl delete -f kubernetes/namespace.yaml --ignore-not-found=true

echo "Cleanup complete!"
