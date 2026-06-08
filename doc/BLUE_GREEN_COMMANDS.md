# 🔵🟢 BLUE-GREEN DEPLOYMENT - QUICK COMMAND REFERENCE

**Latest Update:** June 2026  
**Deployment Files:** `kubernetes/08-frontend-router-service.yaml`  
**Switch Script:** `BLUE_GREEN_SWITCH.ps1`  
**Strategy Guide:** `BLUE_GREEN_STRATEGY.md`

---

## ⚡ QUICK START (Copy & Paste)

### 1️⃣ Deploy Blue-Green Setup (First Time Only)

```bash
# In WSL terminal:
cd ~/HeroVired/Assignment5/Blue-green-Deployment

# Build Docker images in Minikube
eval $(minikube docker-env)
docker compose build

# Deploy all Kubernetes manifests
cd kubernetes
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-mongodb-statefulset.yaml
kubectl apply -f 04-backend-deployment.yaml
kubectl apply -f 05-frontend-blue-deployment.yaml
kubectl apply -f 06-frontend-green-deployment.yaml
kubectl apply -f 08-frontend-router-service.yaml

# Verify deployment
kubectl get pods -n bluegreen -w

# Wait until all pods show "1/1 READY"
```
Switching Traffic:

kubectl get svc frontend-router-service -n bluegreen -o jsonpath='{.spec.selector.version}'

Checking Status:

kubectl get pods -n bluegreen
kubectl get pods -n bluegreen -w
kubectl describe pod <pod-name> -n bluegreen
kubectl get svc -n bluegreen
kubectl get endpoints -n bluegreen

Monitoring:

kubectl get deployments -n bluegreen -w
kubectl logs -n bluegreen -l version=blue -f
kubectl logs -n bluegreen -l version=green -f
kubectl top pods -n bluegreen
kubectl top nodes


Testing:

curl http://localhost:3001/health
curl http://localhost:3004/health
curl http://localhost:3001/api/environment
curl http://localhost:3004/api/environment
curl http://localhost:5000/health

# Register user
curl -X POST http://localhost:3001/api/register -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com","password":"pass123"}'
curl -X POST http://localhost:3004/api/register -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com","password":"pass123"}'

# Get all users
curl http://localhost:5000/api/users

### MongoDB verification commands

Connect to MongoDB:

```bash
kubectl exec -it mongodb-0 -n bluegreen -- mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin"
```

Inside `mongosh`, check the current database and collections:

```javascript
db
show dbs
show collections
db.users.find().pretty()
```

If `db.users.find().pretty()` shows no data, search all databases for user collections:

```javascript
db.getMongo().getDBNames().forEach(dbName => {
  const d = db.getSiblingDB(dbName);
  d.getCollectionNames().forEach(collectionName => {
    if (collectionName.toLowerCase().includes("user")) {
      print(dbName + "." + collectionName + " = " + d.getCollection(collectionName).countDocuments());
    }
  });
});
```

Then switch to the database that contains users and query it:

```javascript
use <database_name>
db.users.find().pretty()
```


View Registered Data:

curl http://localhost:5000/api/users


Option 2: Direct MongoDB

kubectl exec -it mongodb-0 -n bluegreen -- mongosh "mongodb://admin:mongopass@localhost:27017/admin?authSource=admin"

# Inside mongosh:
use bluegreen
db.users.find().pretty()


Option 3: Count Users

curl http://localhost:5000/api/users | jq 'length'

Option 4: Find Specific User

kubectl exec -it mongodb-0 -n bluegreen -- mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin" --eval "db.users.find({email: 'test@example.com'}).pretty()"


Verify Data Persistence

# Register user on Blue
curl http://localhost:3001/api/register ...

# Check via backend
curl http://localhost:5000/api/users

# Switch to Green
kubectl get svc frontend-router-service -n bluegreen -o jsonpath='{.spec.selector.version}'

# Check again
curl http://localhost:5000/api/users


***********************************

************************************

### 2️⃣ Start Port Forwarding (For WSL+Minikube)
```powershell
# From Windows PowerShell (in project directory):
.\START_APP.ps1

# This opens 3 terminals with port forwarding:
# - Blue Frontend:  http://localhost:3001
# - Green Frontend: http://localhost:3004
# - Backend API:    http://localhost:5000
```

### 3️⃣ Verify Everything Works

```powershell
# From Windows PowerShell:
.\VERIFY_BLUE_GREEN.ps1

# Shows complete status report with color coding
# ✅ = Working, ❌ = Failed, ⚠️ = Warning
```

### 4️⃣ Switch Between Versions

```powershell
# Interactive menu (easiest)
.\BLUE_GREEN_SWITCH.ps1

# Or direct switch
.\BLUE_GREEN_SWITCH.ps1 --green    # Switch to Green (v2.0)
.\BLUE_GREEN_SWITCH.ps1 --blue     # Switch to Blue (v1.0)
.\BLUE_GREEN_SWITCH.ps1 --status   # Show current status
.\BLUE_GREEN_SWITCH.ps1 --demo     # Run demo
```

---

## 🎮 Common Commands

### Switching Traffic

| Task | Command |
|------|---------|
| Switch to Green | `.\BLUE_GREEN_SWITCH.ps1 --green` |
| Switch to Blue | `.\BLUE_GREEN_SWITCH.ps1 --blue` |
| Show current active | `wsl kubectl get svc frontend-router-service -n bluegreen -o jsonpath='{.spec.selector.version}'` |
| Interactive menu | `.\BLUE_GREEN_SWITCH.ps1` |

### Checking Status

| Task | Command |
|------|---------|
| Full verification | `.\VERIFY_BLUE_GREEN.ps1` |
| Get all pods | `wsl kubectl get pods -n bluegreen` |
| Watch pods | `wsl kubectl get pods -n bluegreen -w` |
| Pod details | `wsl kubectl describe pod <pod-name> -n bluegreen` |
| Service status | `wsl kubectl get svc -n bluegreen` |
| Endpoints | `wsl kubectl get endpoints -n bluegreen` |

### Monitoring

| Task | Command |
|------|---------|
| Watch deployments | `wsl kubectl get deployments -n bluegreen -w` |
| View Blue logs | `wsl kubectl logs -n bluegreen -l version=blue -f` |
| View Green logs | `wsl kubectl logs -n bluegreen -l version=green -f` |
| Pod resources | `wsl kubectl top pods -n bluegreen` |
| Node resources | `wsl kubectl top nodes` |

### Testing

| Task | Command |
|------|---------|
| Test Blue health | `curl.exe http://localhost:3001/health` |
| Test Green health | `curl.exe http://localhost:3004/health` |
| Test Blue env | `curl.exe http://localhost:3001/api/environment` |
| Test Green env | `curl.exe http://localhost:3004/api/environment` |
| Test Backend | `curl.exe http://localhost:5000/health` |
| Register user (Blue) | `curl.exe -X POST http://localhost:3001/api/register -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com","password":"pass123"}'` |
| Register user (Green) | `curl.exe -X POST http://localhost:3004/api/register -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com","password":"pass123"}'` |
| **Get all users** | `curl.exe http://localhost:5000/api/users` |

### 🔍 VIEW REGISTERED DATA

#### Option 1: View Users via Backend API (Easiest)

```powershell
# From Windows PowerShell:
curl.exe http://localhost:5000/api/users

# Output: JSON array of all registered users
# Example:
# [
#   {
#     "_id": "64a1b2c3d4e5f6g7h8i9j0k1",
#     "name": "John Doe",
#     "email": "john@example.com",
#     "createdAt": "2026-06-08T10:30:45.123Z"
#   },
#   ...
# ]
```

#### Option 2: View Users via MongoDB (Direct Database Access)

```bash
# In WSL terminal:
kubectl exec -it mongodb-0 -n bluegreen -- mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin"

# Inside mongosh shell, run:
db.users.find().pretty()

# Shows all users in formatted JSON
# Exit: Type: exit
```

#### Option 3: Count Total Users

```powershell
# From Windows PowerShell:
$users = curl.exe http://localhost:5000/api/users | ConvertFrom-Json
Write-Host "Total users: $($users.Count)"

# Or using bash:
curl.exe http://localhost:5000/api/users | jq 'length'
```

#### Option 4: Find Specific User

```powershell
# Using mongosh
kubectl exec -it mongodb-0 -n bluegreen -- mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin" --eval "db.users.find({email: 'test@example.com'}).pretty()"

# Or via API (PowerShell):
curl.exe http://localhost:5000/api/users | ConvertFrom-Json | Where-Object { $_.email -eq "test@example.com" } | Format-Table
```

### 📊 VERIFY DATA PERSISTENCE

```bash
# Test 1: Register user on Blue, verify on Green (should be same data)
# 1. Register: curl http://localhost:3001/api/register ...
# 2. Check: curl http://localhost:5000/api/users
# 3. Switch to Green: .\BLUE_GREEN_SWITCH.ps1 --green
# 4. Check again: curl http://localhost:5000/api/users
# → Same users appear = ✅ Data persisted correctly

# Test 2: Direct MongoDB verification
kubectl exec -it mongodb-0 -n bluegreen -- mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin" --eval "db.users.countDocuments()"
# Shows: NumberLong(X) where X = number of registered users
```

---

## 🔄 DEPLOYMENT WORKFLOW COMMANDS

### Step 1: Make Code Changes

```powershell
# Edit frontend-green files
# - frontend-green/public/index.html
# - frontend-green/server.js
# etc.

notepad .\frontend-green\public\index.html
```

### Step 2: Build New Image

```bash
# In WSL terminal:
cd ~/HeroVired/Assignment5/Blue-green-Deployment

# Use Minikube Docker
eval $(minikube docker-env)

# Build only Green image
docker build -t blue-green-deployment-frontend-green:latest ./frontend-green

# Verify image built
docker images | grep frontend-green
```

### Step 3: Restart Pods with New Image

```bash
# In WSL terminal:
# Kubernetes will automatically pull the new image (due to imagePullPolicy: IfNotPresent)

# Option A: Rolling restart
kubectl rollout restart deployment/frontend-green -n bluegreen

# Option B: Wait for auto-update
# (if imagePullPolicy is set to Always)

# Check status
kubectl rollout status deployment/frontend-green -n bluegreen -w
# Wait until "successfully rolled out"
```

### Step 4: Thoroughly Test Green

```bash
# In WSL terminal:
# Test via port forward
curl http://localhost:3004/health
curl http://localhost:3004/api/environment

# In browser:
# http://localhost:3004
# Test all features
```

### Step 5: Switch When Confident

```powershell
# From Windows PowerShell:
.\BLUE_GREEN_SWITCH.ps1 --green

# Or interactive
.\BLUE_GREEN_SWITCH.ps1
# Select option 2
```

### Step 6: Monitor Production

```powershell
# Watch for issues (30 min - 2 hours)
.\BLUE_GREEN_SWITCH.ps1 --monitor

# Check logs
wsl kubectl logs -n bluegreen -l version=green -f
```

### Step 7: Rollback If Issues

```powershell
# Instant rollback if needed
.\BLUE_GREEN_SWITCH.ps1 --blue

# Back to v1.0 immediately
```

---

## 🛠️ DEBUGGING COMMANDS

### Pod Won't Start

```bash
# Check pod status
kubectl describe pod <pod-name> -n bluegreen

# Check logs
kubectl logs <pod-name> -n bluegreen

# Check events
kubectl get events -n bluegreen | grep <pod-name>

# Most common issues:
# - Image not found: Rebuild image in Minikube
# - Port already in use: Check other services
# - Resource quota exceeded: Check Minikube memory
```

### Traffic Not Switching

```bash
# Verify selector was updated
kubectl get service frontend-router-service -n bluegreen \
  -o jsonpath='{.spec.selector.version}'

# Check endpoints
kubectl get endpoints frontend-router-service -n bluegreen

# Force update if stuck
kubectl delete service frontend-router-service -n bluegreen
kubectl apply -f kubernetes/08-frontend-router-service.yaml
```

### Port Forward Not Working

```bash
# Check if process is running
netstat -ano | findstr :3001

# Kill old process if stuck
taskkill /PID <PID> /F

# Restart port forward
kubectl port-forward -n bluegreen svc/frontend-blue-service 3001:3001
```

### MongoDB Connection Issues

```bash
# Test MongoDB connectivity
kubectl exec -it -n bluegreen backend-<pod-suffix> -- \
  curl http://mongodb-service:27017

# Check MongoDB pod
kubectl describe pod mongodb-0 -n bluegreen

# Access MongoDB shell
kubectl exec -it -n bluegreen mongodb-0 -- \
  mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin"

# In mongosh:
db.users.find().pretty()
db.users.countDocuments()
```

---

## 📊 ADVANCED COMMANDS

### Scaling Deployments

```bash
# Scale Blue to 5 replicas
kubectl scale deployment frontend-blue --replicas=5 -n bluegreen

# Scale Green to 3 replicas
kubectl scale deployment frontend-green --replicas=3 -n bluegreen

# Check scaling status
kubectl get deployment -n bluegreen
```

### Updating Images

```bash
# Update Green image to specific version
kubectl set image deployment/frontend-green \
  frontend-green=blue-green-deployment-frontend-green:v2.1 \
  -n bluegreen

# Watch rollout
kubectl rollout status deployment/frontend-green -n bluegreen -w

# Rollback if needed
kubectl rollout undo deployment/frontend-green -n bluegreen

# View rollout history
kubectl rollout history deployment/frontend-green -n bluegreen
```

### Resource Management

```bash
# Set resource limits
kubectl set resources deployment frontend-green \
  --limits=cpu=500m,memory=256Mi \
  --requests=cpu=250m,memory=128Mi \
  -n bluegreen

# Check current resources
kubectl get deployment frontend-green -n bluegreen -o json | \
  jq '.spec.template.spec.containers[].resources'

# Edit deployment directly
kubectl edit deployment frontend-green -n bluegreen
# (Opens vi editor)
```

### View Configuration

```bash
# View ConfigMap
kubectl get configmap bluegreen-config -n bluegreen -o yaml

# Edit ConfigMap
kubectl edit configmap bluegreen-config -n bluegreen

# View all resources in namespace
kubectl get all -n bluegreen

# Export deployment as YAML
kubectl get deployment frontend-green -n bluegreen -o yaml > backup.yaml
```

---

## 🎓 LEARNING COMMANDS

### Understand Kubernetes

```bash
# Explain Kubernetes resources
kubectl explain service
kubectl explain deployment
kubectl explain pod

# Get API versions
kubectl api-versions

# Get resource kinds
kubectl api-resources
```

### Explore Your Deployment

```bash
# Get deployment YAML
kubectl get deployment frontend-blue -n bluegreen -o yaml

# Get service YAML
kubectl get service frontend-router-service -n bluegreen -o yaml

# Get pod YAML
kubectl get pod <pod-name> -n bluegreen -o yaml

# Compare deployed vs file
kubectl diff -f kubernetes/05-frontend-blue-deployment.yaml
```

---

## 🔐 CLEANUP COMMANDS

### Remove Deployments (Careful!)

```bash
# Delete entire namespace (DELETES ALL RESOURCES)
kubectl delete namespace bluegreen

# Delete specific deployment
kubectl delete deployment frontend-green -n bluegreen

# Delete service
kubectl delete service frontend-router-service -n bluegreen

# Delete all in namespace (except namespace itself)
kubectl delete all -n bluegreen
```

### Stop/Delete Minikube

```bash
# Stop Minikube (keeps data)
minikube stop

# Delete Minikube (DELETES ALL DATA)
minikube delete
```

---

## 📋 QUICK REFERENCE TABLE

### Ports Used

| Service | Port | Access | Purpose |
|---------|------|--------|---------|
| Blue Frontend | 3001 | localhost:3001 | v1.0 Basic UI |
| Green Frontend | 3004 | localhost:3004 | v2.0 Enhanced UI |
| Backend API | 5000 | localhost:5000 | User API |
| Router Service | 80 | (internal) | Traffic switching |
| Router NodePort | 30010 | 192.168.49.2:30010 | External access |
| MongoDB | 27017 | (internal only) | Database |

### Environment Variables

| Variable | Value | Where Set |
|----------|-------|-----------|
| NODE_ENV | production | ConfigMap |
| BACKEND_URL | http://backend-service:5000 | ConfigMap |
| PORT (Blue) | 3001 | 05-frontend-blue-deployment.yaml |
| PORT (Green) | 3004 | 06-frontend-green-deployment.yaml |
| MONGO_URI | mongodb://admin:mongopass@mongodb-service:27017/bluegreen?authSource=admin | ConfigMap |

### File Locations

| File | Location | Purpose |
|------|----------|---------|
| Blue Deployment | `kubernetes/05-frontend-blue-deployment.yaml` | Blue v1.0 config |
| Green Deployment | `kubernetes/06-frontend-green-deployment.yaml` | Green v2.0 config |
| Router Service | `kubernetes/08-frontend-router-service.yaml` | Traffic routing |
| Strategy Guide | `BLUE_GREEN_STRATEGY.md` | Detailed explanation |
| Switch Script | `BLUE_GREEN_SWITCH.ps1` | Interactive switching |
| Verify Script | `VERIFY_BLUE_GREEN.ps1` | Health checks |
| Setup Guide | `WSL_COMPLETE_SETUP_GUIDE.sh` | Initial setup |
| Start Script | `START_APP.ps1` | Port forwarding |

---

## 🆘 TROUBLESHOOTING QUICK LINKS

| Issue | Solution |
|-------|----------|
| Minikube won't start | Increase memory: `minikube start --memory=3072mb` |
| Pods stuck in Pending | Check resources: `kubectl describe pod <name>` |
| Port forward not working | Restart: `.\START_APP.ps1` |
| Switch not taking effect | Verify selector: `kubectl get svc frontend-router-service -n bluegreen -o yaml` |
| Can't reach MongoDB | Check pod status: `kubectl describe pod mongodb-0 -n bluegreen` |
| No metrics available | Enable metrics: `minikube addons enable metrics-server` |

---

## 📞 GETTING HELP

### For Understanding Concepts
Read: `BLUE_GREEN_STRATEGY.md` (comprehensive guide)

### For Running Deployments
Run: `.\VERIFY_BLUE_GREEN.ps1` (automated verification)

### For Switching Traffic
Run: `.\BLUE_GREEN_SWITCH.ps1` (interactive menu)

### For Kubernetes Documentation
Use: `kubectl explain <resource>`

### For Debugging
Use: `kubectl describe <resource>` and `kubectl logs <pod>`

---

## ✅ DAILY WORKFLOWS

### Daily Developer Workflow
```powershell
# 1. Start the day
.\START_APP.ps1  # Port forwarding + open browsers

# 2. Make changes
# Edit code...

# 3. Test changes (on Green)
# 4. Rebuild and deploy
wsl docker build -t blue-green-deployment-frontend-green:latest ./frontend-green
wsl kubectl rollout restart deployment/frontend-green -n bluegreen

# 5. Test Green
# Open http://localhost:3004 and verify

# 6. Switch if confident
.\BLUE_GREEN_SWITCH.ps1 --green

# 7. Monitor
.\BLUE_GREEN_SWITCH.ps1 --monitor
```

### Daily DevOps Workflow
```powershell
# 1. Check system health
.\VERIFY_BLUE_GREEN.ps1

# 2. Monitor metrics
wsl kubectl top pods -n bluegreen
wsl kubectl top nodes

# 3. Check logs for errors
wsl kubectl logs -n bluegreen -l version=blue --tail=100
wsl kubectl logs -n bluegreen -l version=green --tail=100

# 4. Prepare for next deployment
# Ensure sufficient resources
# Review deployment checklist
```

---

## 🎉 Final Notes

- **Always test before switching** - Use Green deployment for testing
- **Keep old version running** - Don't delete Blue immediately after switch
- **Monitor actively** - Watch logs and metrics for 1-2 hours after switch
- **Document changes** - Record what was deployed and when
- **Practice rollback** - Test your rollback procedure regularly

---

**Last Updated:** June 2026  
**Status:** Production Ready  
**For Full Guide:** See `BLUE_GREEN_STRATEGY.md`  




Mongodb
harish@Harish:/mnt/d/HeroVired/Assignment5/Blue-green-Deployment$ kubectl describe pod mongodb-0 -n bluegreen | grep MONGO_INITDB_ROOT
      MONGO_INITDB_ROOT_USERNAME:  admin
      MONGO_INITDB_ROOT_PASSWORD:  mongopass
harish@Harish:/mnt/d/HeroVired/Assignment5/Blue-green-Deployment$

harish@Harish:/mnt/d/HeroVired/Assignment5/Blue-green-Deployment$ kubectl exec -it mongodb-0 -n bluegreen -- bash
root@mongodb-0:/# ongosh "mongodb://admin:mongopass@localhost:27017/admin?authSource=admin"
bash: ongosh: command not found
root@mongodb-0:/# mongosh "mongodb://admin:mongopass@localhost:27017/admin?authSource=admin"
Current Mongosh Log ID: 6a266e856ebe6bd3279df8a2
Connecting to:          mongodb://<credentials>@localhost:27017/admin?authSource=admin&directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.8.3
Using MongoDB:          6.0.28
Using Mongosh:          2.8.3

For mongosh info see: https://www.mongodb.com/docs/mongodb-shell/

------
   The server generated these startup warnings when booting
   2026-06-08T05:41:17.198+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
   2026-06-08T05:41:18.949+00:00: vm.max_map_count is too low
------

admin> show collections
system.users
system.version
admin> db.users.find().pretty()
