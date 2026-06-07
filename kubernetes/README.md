# Kubernetes Blue-Green Deployment Setup Guide

## Overview
This directory contains Kubernetes manifests for deploying the blue-green deployment application to a Kubernetes cluster (Minikube for local development).

## Prerequisites

### Windows Installation

#### 1. Install Minikube (Windows)
```powershell
# Using Chocolatey
choco install minikube -y

# Or download directly from GitHub
# https://github.com/kubernetes/minikube/releases/download/latest/minikube-windows-amd64.exe
```

#### 2. Install kubectl (Windows)
```powershell
choco install kubernetes-cli -y
```

#### 3. Install Docker Desktop
- Docker Desktop automatically includes Docker CLI
- Required for building images

#### 4. Build Docker Images First
```powershell
cd ..
docker compose build
```

### Linux/Mac Installation

```bash
# Using Homebrew (Mac)
brew install minikube
brew install kubectl

# Using package manager (Linux)
sudo apt-get install minikube
sudo apt-get install kubectl
```

## Quick Start

### 1. Start Minikube Cluster
```bash
# Start Minikube with sufficient resources
minikube start --cpus 4 --memory 4096 --driver docker

# Verify Minikube is running
minikube status

# Get Minikube IP (needed for NodePort access)
minikube ip
```

### 2. Build and Load Images into Minikube

```bash
# Set Docker environment to Minikube's Docker daemon
# Windows PowerShell:
minikube docker-env | Invoke-Expression

# Linux/Mac:
eval $(minikube docker-env)

# Build images in Minikube environment
cd ..
docker compose build

# Verify images are in Minikube
docker images | grep blue-green
```

### 3. Deploy to Kubernetes

#### Option A: Use Deployment Script
```bash
# Windows
cd kubernetes
./deploy.bat

# Linux/Mac
cd kubernetes
chmod +x deploy.sh
./deploy.sh
```

#### Option B: Manual Deployment
```bash
cd kubernetes

# Apply all manifests in order
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-mongodb-statefulset.yaml
kubectl apply -f 04-backend-deployment.yaml
kubectl apply -f 05-frontend-blue-deployment.yaml
kubectl apply -f 06-frontend-green-deployment.yaml
kubectl apply -f 07-ingress.yaml

# Wait for all pods to be ready
kubectl get pods -n bluegreen -w
```

### 4. Verify Deployment

```bash
# Check all resources
kubectl get all -n bluegreen

# Check pods
kubectl get pods -n bluegreen

# Check services
kubectl get svc -n bluegreen

# Check StatefulSet
kubectl get statefulset -n bluegreen

# View deployment details
kubectl describe deployment backend -n bluegreen

# View pod logs
kubectl logs -n bluegreen -l app=backend
kubectl logs -n bluegreen -l app=mongodb
```

## Accessing the Applications

### Using NodePort (Direct Access)

1. **Get Minikube IP:**
   ```bash
   minikube ip
   ```

2. **Access via NodePort:**
   - Blue Frontend: `http://<minikube-ip>:30001`
   - Green Frontend: `http://<minikube-ip>:30004`
   - Backend API: `http://<minikube-ip>:30005` (if exposed)

### Using Port Forwarding

```bash
# Forward Blue Frontend
kubectl port-forward -n bluegreen svc/frontend-blue-service 3001:3001

# Forward Green Frontend (in another terminal)
kubectl port-forward -n bluegreen svc/frontend-green-service 3004:3004

# Forward Backend (in another terminal)
kubectl port-forward -n bluegreen svc/backend-service 5000:5000

# Then access:
# - Blue: http://localhost:3001
# - Green: http://localhost:3004
# - Backend: http://localhost:5000
```

## Testing the Deployment

### 1. Test Backend Health
```bash
curl http://localhost:5000/health
# Expected: {"status":"OK","message":"Backend is running"}
```

### 2. Test Frontend Environment
```bash
# Blue Frontend
curl http://localhost:3001/health
# Expected: {"status":"OK","environment":"blue","message":"Frontend Blue is running"}

# Green Frontend
curl http://localhost:3004/health
# Expected: {"status":"OK","environment":"green","message":"Frontend Green is running"}
```

### 3. Test Registration (via Green Frontend)
```bash
curl -X POST http://localhost:3004/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"TestUser","email":"test@example.com","password":"pass1234"}'
# Expected: {"message":"User registered successfully","user":{...}}
```

### 4. Test Data Persistence
```bash
# Get all users
curl http://localhost:5000/api/users
# Should return registered users from MongoDB
```

### 5. Test MongoDB Directly
```bash
# Connect to MongoDB pod
kubectl exec -it -n bluegreen mongodb-0 -- mongosh mongodb://localhost:27017/bluegreen

# In mongosh shell:
> db.users.find().pretty()
> db.users.countDocuments()
```

## Kubernetes Manifest Details

### 1. **Namespace (01-namespace.yaml)**
- Creates isolated namespace `bluegreen` for the application
- Prevents name conflicts with other deployments

### 2. **ConfigMap (02-configmap.yaml)**
- Stores configuration for all services
- MongoDB URI: points to MongoDB service DNS
- Backend URL: points to Backend service DNS
- Environment variables centralized management

### 3. **MongoDB StatefulSet (03-mongodb-statefulset.yaml)**
- StatefulSet for stateful MongoDB data
- Persistent Volume Claim: 1Gi storage
- Health checks:
  - **Liveness Probe**: Ensures pod restarts if MongoDB dies
  - **Readiness Probe**: Ensures traffic only sent when ready
- Resource limits for stability

### 4. **Backend Deployment (04-backend-deployment.yaml)**
- 2 replicas for high availability
- Rolling update strategy (maxSurge: 1, maxUnavailable: 0 = zero downtime)
- Health checks:
  - **Liveness Probe**: `/health` endpoint on port 5000
  - **Readiness Probe**: Ensures pod is ready for traffic
  - **Startup Probe**: Gives extra time for app initialization
- ClusterIP Service for internal communication
- Resource requests/limits: 128Mi memory, 100m CPU

### 5. **Frontend Blue Deployment (05-frontend-blue-deployment.yaml)**
- 2 replicas for load balancing
- Port: 3001
- Health checks on `/health` endpoint
- NodePort Service (30001) for external access
- Same rolling update strategy

### 6. **Frontend Green Deployment (06-frontend-green-deployment.yaml)**
- 2 replicas for high availability
- Port: 3004
- Health checks on `/health` endpoint
- NodePort Service (30004) for external access
- Allows simultaneous blue-green testing

### 7. **Ingress (07-ingress.yaml)**
- Routes traffic to different frontends by hostname
- `blue.local` → Frontend Blue
- `green.local` → Frontend Green
- `api.local` → Backend API
- Requires Ingress Controller (nginx-ingress)

## Health Checks Explained

### Liveness Probe
- **Purpose**: Detect if pod is stuck/crashed
- **Action**: Restart pod if health check fails
- **Example**: `httpGet /health on port 5000`
- **Failure**: 3 consecutive failures → pod restart

### Readiness Probe
- **Purpose**: Detect if pod is ready to receive traffic
- **Action**: Remove pod from service endpoints if failing
- **Example**: `httpGet /health on port 5000`
- **Failure**: 2 consecutive failures → no traffic

### Startup Probe
- **Purpose**: Give app time to initialize before liveness checks
- **Action**: Disable liveness probe until startup succeeds
- **Example**: `httpGet /health on port 5000`
- **Failure**: 30 × 10s = 5 minutes max startup time

## Troubleshooting

### Pods stuck in `Pending`
```bash
kubectl describe pod <pod-name> -n bluegreen
# Check events section for resource/scheduling issues

# May need more Minikube resources:
minikube stop
minikube start --cpus 4 --memory 6144
```

### Pods stuck in `CrashLoopBackOff`
```bash
# Check pod logs
kubectl logs <pod-name> -n bluegreen
kubectl logs <pod-name> -n bluegreen --previous

# Check liveness probe failures
kubectl describe pod <pod-name> -n bluegreen
```

### Service not accessible
```bash
# Check endpoints
kubectl get endpoints -n bluegreen

# Check service selector
kubectl get svc -n bluegreen -o yaml | grep selector -A 5

# Check pod labels
kubectl get pods -n bluegreen --show-labels
```

### MongoDB data not persisting
```bash
# Check PVC status
kubectl get pvc -n bluegreen

# Check PV status
kubectl get pv

# Verify volume is mounted
kubectl describe pod mongodb-0 -n bluegreen | grep -A 10 "Mounts"
```

## Scaling the Deployment

```bash
# Scale Backend replicas
kubectl scale deployment backend --replicas=3 -n bluegreen

# Scale Frontend Blue
kubectl scale deployment frontend-blue --replicas=3 -n bluegreen

# Scale Frontend Green
kubectl scale deployment frontend-green --replicas=3 -n bluegreen

# Check scaled deployments
kubectl get deployment -n bluegreen
```

## Updating Deployment

```bash
# After code changes, rebuild images in Minikube
eval $(minikube docker-env)  # or minikube docker-env | Invoke-Expression on Windows
docker compose build

# Restart deployment to pull new image
kubectl rollout restart deployment/backend -n bluegreen
kubectl rollout restart deployment/frontend-blue -n bluegreen
kubectl rollout restart deployment/frontend-green -n bluegreen

# Monitor rollout
kubectl rollout status deployment/backend -n bluegreen -w
```

## Cleanup

```bash
# Delete all resources in namespace
kubectl delete namespace bluegreen

# Or delete individual components
kubectl delete -f 07-ingress.yaml
kubectl delete -f 06-frontend-green-deployment.yaml
kubectl delete -f 05-frontend-blue-deployment.yaml
kubectl delete -f 04-backend-deployment.yaml
kubectl delete -f 03-mongodb-statefulset.yaml
kubectl delete -f 02-configmap.yaml
kubectl delete -f 01-namespace.yaml

# Stop Minikube
minikube stop

# Delete Minikube cluster (optional)
minikube delete
```

## Summary of Port Mappings

| Service | Internal Port | NodePort | Access |
|---------|---------------|----------|--------|
| MongoDB | 27017 | - | Internal only |
| Backend | 5000 | 30005 | `http://<minikube-ip>:30005` |
| Frontend Blue | 3001 | 30001 | `http://<minikube-ip>:30001` |
| Frontend Green | 3004 | 30004 | `http://<minikube-ip>:30004` |

## Part 3 Deliverables ✅

- [x] **Kubernetes Deployment Manifests** (6 files)
- [x] **Service Resources** for all applications
- [x] **Health Checks** (Liveness, Readiness, Startup probes)
- [x] **StatefulSet for MongoDB** with persistent storage
- [x] **Ingress Configuration** for routing
- [x] **Deployment Scripts** for automation
- [x] **Comprehensive Documentation** with verification steps
