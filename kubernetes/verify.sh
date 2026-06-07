#!/bin/bash

# Kubernetes Verification Script

NAMESPACE="bluegreen"

echo "=========================================="
echo "Kubernetes Deployment Verification"
echo "=========================================="
echo ""

echo "1. Checking Namespace:"
kubectl get namespace | grep $NAMESPACE
echo ""

echo "2. Checking Pods Status:"
kubectl get pods -n $NAMESPACE
echo ""

echo "3. Checking Services:"
kubectl get svc -n $NAMESPACE
echo ""

echo "4. Checking Deployments:"
kubectl get deployments -n $NAMESPACE
echo ""

echo "5. Checking StatefulSets:"
kubectl get statefulset -n $NAMESPACE
echo ""

echo "6. Checking Persistent Volumes:"
kubectl get pvc -n $NAMESPACE
echo ""

echo "7. Pod Details:"
echo "   MongoDB:"
kubectl get pod -n $NAMESPACE -l app=mongodb -o wide
echo ""
echo "   Backend:"
kubectl get pod -n $NAMESPACE -l app=backend -o wide
echo ""
echo "   Frontend Blue:"
kubectl get pod -n $NAMESPACE -l version=blue -o wide
echo ""
echo "   Frontend Green:"
kubectl get pod -n $NAMESPACE -l version=green -o wide
echo ""

echo "8. Describe Services:"
echo "   Backend Service:"
kubectl describe svc backend-service -n $NAMESPACE | grep -A 5 "Endpoints"
echo ""

echo "9. Check Logs:"
echo "   Backend Pod Log:"
kubectl logs -n $NAMESPACE -l app=backend --tail=10 --all-containers=true
echo ""

echo "=========================================="
echo "Verification Complete"
echo "=========================================="
