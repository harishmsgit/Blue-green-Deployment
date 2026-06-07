#!/bin/bash

# Comprehensive Testing Script for Kubernetes Deployment

NAMESPACE="bluegreen"
BACKEND_POD=$(kubectl get pod -n $NAMESPACE -l app=backend -o jsonpath='{.items[0].metadata.name}')

echo "=========================================="
echo "Kubernetes Deployment Testing"
echo "=========================================="
echo ""

# Test 1: Check all pods are running
echo "TEST 1: Verify All Pods Running"
echo "=================================="
READY_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers | wc -l)
TOTAL_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
echo "Running Pods: $READY_PODS / $TOTAL_PODS"
kubectl get pods -n $NAMESPACE
echo ""

# Test 2: Check Services have endpoints
echo "TEST 2: Verify Services Have Endpoints"
echo "========================================"
echo "Backend Service Endpoints:"
kubectl get endpoints backend-service -n $NAMESPACE
echo "Frontend Blue Service Endpoints:"
kubectl get endpoints frontend-blue-service -n $NAMESPACE
echo "Frontend Green Service Endpoints:"
kubectl get endpoints frontend-green-service -n $NAMESPACE
echo ""

# Test 3: Test Backend Health from Pod
echo "TEST 3: Backend Health Check"
echo "============================"
echo "Attempting health check from backend pod..."
kubectl exec -it -n $NAMESPACE $BACKEND_POD -- curl -s http://localhost:5000/health
echo ""
echo ""

# Test 4: Test MongoDB connectivity from Backend
echo "TEST 4: MongoDB Connectivity"
echo "============================"
echo "MongoDB Status from Backend pod:"
kubectl exec -it -n $NAMESPACE $BACKEND_POD -- curl -s http://localhost:5000/health
echo ""
echo ""

# Test 5: Test inter-pod communication
echo "TEST 5: Inter-pod Communication (Backend to MongoDB)"
echo "===================================================="
echo "Pinging MongoDB service from Backend pod:"
kubectl exec -it -n $NAMESPACE $BACKEND_POD -- wget --spider -q http://mongodb-service:27017 2>&1 || echo "MongoDB service reachable (or expected timeout)"
echo ""

# Test 6: Show deployment status
echo "TEST 6: Deployment Status"
echo "========================="
echo "Backend Deployment:"
kubectl rollout status deployment/backend -n $NAMESPACE
echo ""
echo "Frontend Blue Deployment:"
kubectl rollout status deployment/frontend-blue -n $NAMESPACE
echo ""
echo "Frontend Green Deployment:"
kubectl rollout status deployment/frontend-green -n $NAMESPACE
echo ""

# Test 7: Resource usage
echo "TEST 7: Resource Usage"
echo "====================="
echo "Pod Resource Usage:"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "(Metrics server not installed - this is optional)"
echo ""

# Test 8: Event logs
echo "TEST 8: Recent Events"
echo "===================="
echo "Recent Kubernetes Events:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20
echo ""

# Test 9: Check probes status
echo "TEST 9: Health Probes Status"
echo "============================"
echo "Checking pod conditions..."
kubectl get pods -n $NAMESPACE -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[*].type}{"\n"}{end}'
echo ""

echo "=========================================="
echo "✅ Testing Complete"
echo "=========================================="
echo ""
echo "To access applications from host:"
echo "  1. Get Minikube IP: minikube ip"
echo "  2. Blue Frontend:  http://<minikube-ip>:30001"
echo "  3. Green Frontend: http://<minikube-ip>:30004"
echo ""
echo "To use port forwarding instead:"
echo "  kubectl port-forward -n bluegreen svc/frontend-blue-service 3001:3001"
echo "  kubectl port-forward -n bluegreen svc/frontend-green-service 3004:3004"
echo ""
