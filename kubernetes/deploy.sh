#!/bin/bash

# Kubernetes Deployment Script for Blue-Green Application

set -e

NAMESPACE="bluegreen"

echo "=========================================="
echo "Blue-Green Deployment to Kubernetes"
echo "=========================================="

# Step 1: Create namespace
echo "[1/5] Creating namespace..."
kubectl apply -f 01-namespace.yaml

# Step 2: Apply ConfigMap
echo "[2/5] Creating ConfigMap..."
kubectl apply -f 02-configmap.yaml

# Step 3: Deploy MongoDB
echo "[3/5] Deploying MongoDB StatefulSet..."
kubectl apply -f 03-mongodb-statefulset.yaml
echo "Waiting for MongoDB to be ready..."
kubectl rollout status -n $NAMESPACE statefulset/mongodb --timeout=300s

# Step 4: Deploy Backend
echo "[4/5] Deploying Backend..."
kubectl apply -f 04-backend-deployment.yaml
echo "Waiting for Backend to be ready..."
kubectl rollout status -n $NAMESPACE deployment/backend --timeout=300s

# Step 5: Deploy Frontends
echo "[5/5] Deploying Frontend (Blue & Green)..."
kubectl apply -f 05-frontend-blue-deployment.yaml
kubectl apply -f 06-frontend-green-deployment.yaml
echo "Waiting for Frontends to be ready..."
kubectl rollout status -n $NAMESPACE deployment/frontend-blue --timeout=300s
kubectl rollout status -n $NAMESPACE deployment/frontend-green --timeout=300s

# Deploy Ingress (optional)
echo "Deploying Ingress routes..."
kubectl apply -f 07-ingress.yaml

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Verify deployment:"
echo "  kubectl get all -n $NAMESPACE"
echo "  kubectl get pods -n $NAMESPACE -w"
echo ""
echo "Access the applications:"
echo "  Blue Frontend:  http://localhost:30001"
echo "  Green Frontend: http://localhost:30004"
echo "  Backend API:    http://localhost:30005"
echo ""
