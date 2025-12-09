#!/bin/bash

set -e

echo "Deploying MuchTodo to Kubernetes..."

# Create namespace
echo "Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml

# Deploy MongoDB
echo "Deploying MongoDB..."
kubectl apply -f kubernetes/mongodb/

# Deploy Backend
echo "Deploying Backend..."
kubectl apply -f kubernetes/backend/

# Deploy Ingress
echo "Deploying Ingress..."
kubectl apply -f kubernetes/ingress.yaml

echo ""
echo "Deployment initiated!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n muchtodo"
echo ""
echo "Wait for pods to be ready:"
echo "  kubectl wait --for=condition=ready pod -l app=backend -n muchtodo --timeout=120s"
echo ""
echo "Access the application:"
echo "  NodePort: http://localhost:30080/health"
echo "  Ingress: http://muchtodo.local (add to /etc/hosts)"

