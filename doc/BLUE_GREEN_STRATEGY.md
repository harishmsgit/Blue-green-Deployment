# 🔵🟢 BLUE-GREEN DEPLOYMENT STRATEGY - COMPREHENSIVE GUIDE

## 📋 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Deployment Versions](#deployment-versions)
4. [Switching Mechanism](#switching-mechanism)
5. [Deployment Workflow](#deployment-workflow)
6. [Commands Reference](#commands-reference)
7. [Demonstration Guide](#demonstration-guide)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## 🎯 Overview

Blue-Green Deployment is a release management strategy that reduces downtime and risk by running two identical production environments. At any given time, only one is live, handling all production traffic. The other is idle, ready to receive updates.

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Zero Downtime** | Switch occurs in milliseconds, users never experience downtime |
| **Instant Rollback** | If issues detected, switch back to previous version immediately |
| **Full Testing** | Test new version thoroughly before traffic switch |
| **Easy Rollback** | No complex orchestration, just change a label |
| **A/B Testing** | Can run both versions simultaneously for gradual rollout (with load balancer) |
| **Resource Efficient** | Both versions run, but only one receives traffic |

### When to Use Blue-Green

✅ **Good for:**
- Applications with strict uptime requirements
- Deployments where rollback must be instant
- Applications where validation needs production-like testing
- Teams wanting simple, reliable deployments

❌ **Not ideal for:**
- Resource-constrained environments (both versions use resources)
- Applications with large databases (migrations needed for both)
- Frequent small updates (overhead not justified)

---

## 🏗️ Architecture

### Current Setup

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                    (Minikube / WSL)                          │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          Frontend Router Service                      │   │
│  │   (Switches traffic between Blue & Green)            │   │
│  │   Port 80 → directs to active version                │   │
│  │   Port 30010 → NodePort access                       │   │
│  └────────────────┬─────────────────────────────────────┘   │
│                   │                                           │
│        ┌──────────┴──────────────┐                           │
│        │ Routes to:              │                           │
│        ├─ version: blue (70%)    │                           │
│        └─ version: green (30%)   │                           │
│                   │                                           │
│    ┌──────────────┼──────────────┐                           │
│    │              │              │                           │
│    ▼              ▼              ▼                           │
│ ┌────────┐  ┌──────────┐  ┌──────────┐                       │
│ │Backend │  │Blue v1.0 │  │Green v2.0│                       │
│ │        │  │(Basic)   │  │(Enhanced)│                       │
│ │MongoDB │  │3 replicas│  │3 replicas│                       │
│ │        │  │ACTIVE ✅ │  │STANDBY   │                       │
│ └────────┘  └──────────┘  └──────────┘                       │
│                                                               │
│    All versions share:                                       │
│    - MongoDB backend (27017)                                │
│    - Backend service (5000)                                 │
│    - Configuration (ConfigMap)                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Network Flow

**Current State (Blue Active):**
```
User Request
   │
   ├─ http://localhost:3001 (via port-forward)
   │  OR
   ├─ http://localhost:3001 (via router)
   │  OR
   ├─ http://minikube-ip:30010 (NodePort)
   │
   ▼
Frontend Router Service (selector: version=blue)
   │
   ▼
Blue Frontend Pods (v1.0)
   ├─ Serves UI
   ├─ Proxies API calls to Backend
   │
   ▼
Backend Service (MongoDB queries)
   │
   ▼
MongoDB (data persistence)
```

---

## 📦 Deployment Versions

### Blue Deployment (v1.0 - BASIC)

**Version:** 1.0  
**Status:** Production-stable  
**UI:** Simple, minimal  
**Port:** 3001 (port-forward) / 30001 (NodePort)  

**Features:**
- ✅ Simple registration form
- ✅ Name, Email, Password fields
- ✅ Minimal UI, fast loading
- ✅ Proven and stable

**HTML/JS Changes:**
```html
<span class="badge">🔵 BLUE DEPLOYMENT <span class="version">BASIC VERSION</span></span>
<h1>User Registration</h1>
<p class="subtitle">Blue frontend - Basic registration form (v1.0)</p>
```

**Container:**
- Image: `blue-green-deployment-frontend-blue:latest`
- Base Port: 3001
- Labels: `app=frontend, version=blue`

---

### Green Deployment (v2.0 - ENHANCED)

**Version:** 2.0  
**Status:** Ready for testing  
**UI:** Enhanced with dashboard  
**Port:** 3004 (port-forward) / 30004 (NodePort)  

**New Features:**
- ✅ Advanced registration form
- ✅ Dashboard with user management
- ✅ Real-time user statistics
- ✅ User list viewer with pagination
- ✅ Modern UI with navigation tabs
- ✅ Better visual design

**HTML/JS Changes:**
```html
<span class="badge">🟢 GREEN DEPLOYMENT <span class="version">ENHANCED VERSION</span></span>
<h1>User Registration</h1>
<p class="subtitle">Green frontend - Enhanced UI with dashboard (v2.0)</p>

<!-- NEW SECTION -->
<div id="dashboard" class="section">
    <h2>User Dashboard</h2>
    <div class="stats">
        <div class="stat-box">
            <div class="number" id="userCount">0</div>
            <div class="label">Total Users</div>
        </div>
    </div>
    <div class="user-list">
        <h2>Registered Users</h2>
        <div id="usersList"></div>
    </div>
</div>
```

**Container:**
- Image: `blue-green-deployment-frontend-green:latest`
- Base Port: 3004
- Labels: `app=frontend, version=green`

---

## 🔄 Switching Mechanism

### How the Router Service Works

The `frontend-router-service` in Kubernetes uses a simple but powerful mechanism:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-router-service
spec:
  selector:
    version: blue    # ← THIS LINE DETERMINES WHERE TRAFFIC GOES
  ports:
    - port: 80
      targetPort: 3000
```

### Traffic Flow Logic

```
Service selector: version=blue
         │
         ├─ Finds ALL pods with label version=blue
         │  (Can be 1, 2, 3, or more replicas)
         │
         ├─ Load balances traffic across them
         │
         └─ Any pod with version=green is IGNORED
            (Not selected by this service)
```

### Switching Process

**Step 1: Identify Pods to Switch From**
```
Current selector: version=blue
Active pods: 3 blue frontend pods
Serving: 100% of traffic
```

**Step 2: Prepare Target Version**
```
Target selector: version=green
Target pods: 3 green frontend pods
Status: Running and healthy, waiting to be selected
```

**Step 3: Update Service Selector**
```
kubectl patch service frontend-router-service \
  -n bluegreen \
  -p '{"spec":{"selector":{"version":"green"}}}'

Result: Kubernetes instantly updates internal load balancer
```

**Step 4: Instant Traffic Switch**
```
Time T-1: Traffic routes to blue pods
Time T:   Selector changes to green
Time T+1: Traffic routes to green pods
(Entire switch takes < 100ms)
```

**Step 5: Verify Switch**
```
kubectl get service frontend-router-service -n bluegreen
Output shows:
  - Endpoints now point to green pod IPs
  - Blue pods still running but not receiving traffic
```

---

## 📊 Deployment Workflow

### Pre-Deployment Phase (Blue is ACTIVE)

```
┌─────────────────┐
│  BLUE ACTIVE    │  ← Serving 100% traffic
│  v1.0           │     3 replicas running
│  3 pods         │     1000 users/min ✅
└─────────────────┘

┌─────────────────┐
│  GREEN STANDBY  │  ← Idle, no traffic
│  v2.0           │     3 replicas running
│  3 pods         │     Ready but not selected
└─────────────────┘
```

**Resource Usage:**
- Blue: 3 × 128Mi RAM = 384Mi (ACTIVE)
- Green: 3 × 128Mi RAM = 384Mi (IDLE)
- **Total: 768Mi** (both versions consume resources)

---

### Deployment Phase (New version deployed to Green)

```
Step 1: Code changes committed
        └─ frontend-green/server.js updated
        └─ frontend-green/public/index.html updated

Step 2: Docker image built
        └─ docker build -t blue-green-deployment-frontend-green:latest .

Step 3: Image loaded into Minikube
        └─ Minikube's Docker daemon gets new image

Step 4: Kubernetes rolls out update
        └─ Green deployment updated with new image
        └─ Rolling update starts (maxSurge=1, maxUnavailable=0)
        └─ New pods created, old pods terminated
        └─ No impact on Blue (still serving traffic)

Step 5: Health checks validate Green
        └─ Readiness probe: pods become available in 10-30s
        └─ Liveness probe: keeps pods healthy during update
        └─ All 3 replicas ready

Step 6: Testing phase
        └─ Developers test Green via localhost:3004
        └─ QA validates all features
        └─ Load testing with mirror traffic possible
        └─ Zero impact on production (Blue is active)
```

---

### Switch Phase (Traffic switched to Green)

```
Decision: "Green is validated, ready for production"

Command: .\BLUE_GREEN_SWITCH.ps1 --green
         OR
         kubectl patch service frontend-router-service \
           -n bluegreen \
           -p '{"spec":{"selector":{"version":"green"}}}'

Execution:
  Time T:     Selector changes to version=green
  Time T+50ms: Kubernetes updates iptables rules
  Time T+100ms: First request routes to green
  Time T+200ms: 100% traffic on Green

Result:
  ┌─────────────────┐
  │  BLUE STANDBY   │  ← Ready for rollback
  │  v1.0           │     Still running, not selected
  │  3 pods         │     Can be switched back instantly
  └─────────────────┘

  ┌─────────────────┐
  │  GREEN ACTIVE   │  ← Serving 100% traffic
  │  v2.0           │     3 replicas running
  │  3 pods         │     1000 users/min ✅
  └─────────────────┘
```

---

### Post-Switch Phase (Validation & Cleanup)

```
Hour 1-6: Heavy Monitoring
  ├─ Error rate monitoring (should be 0%)
  ├─ User feedback channels
  ├─ Automated alerts for anomalies
  ├─ Database query performance
  └─ API response time metrics

If GREEN is STABLE (after 6+ hours):
  ├─ Declare Green as new Blue
  ├─ Plan new updates for old Blue
  └─ Keep Blue running for quick rollback (48 hours)

If GREEN has ISSUES (within 2 hours):
  ├─ Switch back to Blue immediately
  ├─ Root cause analysis
  ├─ Fix issues in Green code
  ├─ Re-deploy and re-test Green
  └─ Try again with proper fixes
```

---

### Rollback Phase (If Issues Detected)

```
Issue detected in Green (e.g., registration failing)

Immediate Action:
  Command: .\BLUE_GREEN_SWITCH.ps1 --blue

Execution:
  Time T:      Selector changes to version=blue
  Time T+100ms: Traffic routed back to Blue
  Result:      Blue v1.0 is active, users unaffected

Recovery:
  ├─ 99% of users never notice the issue
  ├─ Only requests in-flight during switch may have issues
  ├─ Debug Green deployment thoroughly
  ├─ Fix identified issues
  ├─ Re-run QA testing
  └─ Attempt switch again
```

---

## 🎮 Commands Reference

### Basic Switching

```powershell
# Switch to Green deployment
.\BLUE_GREEN_SWITCH.ps1 --green

# Switch to Blue deployment
.\BLUE_GREEN_SWITCH.ps1 --blue

# Interactive mode (menu-driven)
.\BLUE_GREEN_SWITCH.ps1

# Show current status
.\BLUE_GREEN_SWITCH.ps1 --status

# Automated demonstration
.\BLUE_GREEN_SWITCH.ps1 --demo
```

### Manual kubectl Commands

```bash
# Check current active version
kubectl get service frontend-router-service -n bluegreen \
  -o jsonpath='{.spec.selector.version}'

# Show which pods are selected
kubectl get pods -n bluegreen --show-labels | grep version

# Switch to Green (manual)
kubectl patch service frontend-router-service \
  -n bluegreen \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Switch to Blue (manual)
kubectl patch service frontend-router-service \
  -n bluegreen \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Watch endpoints being updated
kubectl get endpoints frontend-router-service -n bluegreen -w

# Verify endpoints point to Green
kubectl get endpoints frontend-router-service -n bluegreen \
  -o jsonpath='{.subsets[*].addresses[*].targetRef.labels.version}'
```

### Deployment Management

```bash
# View Blue deployment
kubectl describe deployment frontend-blue -n bluegreen

# View Green deployment
kubectl describe deployment frontend-green -n bluegreen

# Scale Blue to 4 replicas
kubectl scale deployment frontend-blue --replicas=4 -n bluegreen

# Scale Green to 2 replicas
kubectl scale deployment frontend-green --replicas=2 -n bluegreen

# Update Green image
kubectl set image deployment/frontend-green \
  frontend-green=blue-green-deployment-frontend-green:v2.0 \
  -n bluegreen

# View rollout history
kubectl rollout history deployment/frontend-green -n bluegreen

# Rollback to previous version
kubectl rollout undo deployment/frontend-green -n bluegreen
```

### Monitoring

```bash
# Watch pods during switch
kubectl get pods -n bluegreen -w

# View logs of Green deployment
kubectl logs -n bluegreen -l version=green -f

# Check service endpoints
kubectl get endpoints -n bluegreen -w

# Monitor resource usage
kubectl top pods -n bluegreen
kubectl top nodes
```

---

## 🎬 Demonstration Guide

### Scenario 1: Simple Switch (2 minutes)

```powershell
# Terminal 1: Watch pods
wsl kubectl get pods -n bluegreen -w

# Terminal 2: Switch to Green
.\BLUE_GREEN_SWITCH.ps1 --green

# Terminal 3: Test access
curl.exe http://localhost:3001/api/environment
# Output: {"environment":"green",...}

# Observe in Terminal 1: No pods restarted, just selector changed
```

### Scenario 2: Interactive Testing (10 minutes)

```powershell
# Start interactive switch menu
.\BLUE_GREEN_SWITCH.ps1

# Menu options:
# 1. Switch to Blue (v1.0)
# 2. Switch to Green (v2.0)
# 3. Show detailed status
# 4. Test both deployments
# 5. Monitor active deployment
# 6. Exit

# Select option 4 to test both versions
# Test Blue at http://localhost:3001/api/environment
# Test Green at http://localhost:3004/api/environment
# Notice the difference in UI and features

# Select option 2 to switch to Green
# Both deployments work with different UIs
```

### Scenario 3: Full Deployment Cycle (30 minutes)

```powershell
# Step 1: Verify initial state (Blue is active)
.\BLUE_GREEN_SWITCH.ps1 --status
# Output: Blue is active, Green is standby

# Step 2: Make changes to Green
# Edit: frontend-green/public/index.html
# Add new feature or fix a bug

# Step 3: Rebuild Green image
wsl docker build -t blue-green-deployment-frontend-green:latest ./frontend-green

# Step 4: Trigger Kubernetes update
wsl kubectl rollout restart deployment/frontend-green -n bluegreen

# Step 5: Wait for Green to be ready
wsl kubectl get pods -n bluegreen -l version=green -w
# Wait until all show "1/1 Ready"

# Step 6: Test Green extensively
curl.exe http://localhost:3004/api/environment
curl.exe http://localhost:3004/health
# Open browser at http://localhost:3004
# Register test users, verify all features work

# Step 7: Switch to Green when confident
.\BLUE_GREEN_SWITCH.ps1 --green
# Result: All traffic now goes to Green

# Step 8: Monitor in production
.\BLUE_GREEN_SWITCH.ps1 --monitor
# Watch for any issues

# Step 9: If issues found, rollback
.\BLUE_GREEN_SWITCH.ps1 --blue
# Back to Blue immediately

# Step 10: If Green proves stable (4+ hours), update Blue
# Now Green becomes the new stable version
```

### Scenario 4: Zero-Downtime Update (5 minutes + validation)

```powershell
# Simulated scenario:
# Blue is serving 1000 requests/minute

# Step 1: Deploy to Green (happens in background)
wsl kubectl set image deployment/frontend-green \
  frontend-green=blue-green-deployment-frontend-green:v2.5 \
  -n bluegreen

# Step 2: Wait for Green rollout (30 seconds, rolling update)
wsl kubectl rollout status deployment/frontend-green -n bluegreen

# Step 3: Run automated tests against Green
.\test-deployment.ps1 green

# Step 4: If tests pass, switch
.\BLUE_GREEN_SWITCH.ps1 --green

# Result:
# - Blue was active throughout steps 1-3 (serving 1000 req/min)
# - NO users experienced downtime
# - 100% uptime maintained
# - Green is now production
# - Can rollback if needed
```

---

## 🔍 Troubleshooting

### Issue 1: Selector Change Not Taking Effect

**Symptom:** Changed selector but traffic still goes to old version

**Diagnosis:**
```bash
kubectl get service frontend-router-service -n bluegreen \
  -o jsonpath='{.spec.selector.version}'
# Check if output matches what you changed to
```

**Solution:**
```bash
# Force update using apply
kubectl apply -f kubernetes/08-frontend-router-service.yaml

# Or verify the patch was applied
kubectl describe service frontend-router-service -n bluegreen
# Check the Selector field
```

---

### Issue 2: Endpoints Not Updated After Switch

**Symptom:** `kubectl get endpoints` still shows old pod IPs

**Diagnosis:**
```bash
kubectl get endpoints frontend-router-service -n bluegreen
# Should show IPs of pods matching the new selector
```

**Solution:**
```bash
# Force endpoint refresh
kubectl delete service frontend-router-service -n bluegreen
kubectl apply -f kubernetes/08-frontend-router-service.yaml

# Wait 10 seconds for endpoints to update
sleep 10
kubectl get endpoints frontend-router-service -n bluegreen
```

---

### Issue 3: New Version Not Ready

**Symptom:** Try to switch but target version has pods in pending/failed state

**Diagnosis:**
```bash
kubectl get pods -n bluegreen -l version=green
# Check Status column for non-Running states
```

**Solution:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n bluegreen

# Check logs
kubectl logs <pod-name> -n bluegreen

# Fix issues (rebuild image, check resources)
# Then restart deployment
kubectl rollout restart deployment/frontend-green -n bluegreen

# Wait for all pods to be ready
kubectl wait --for=condition=Ready pod \
  -l version=green \
  -n bluegreen \
  --timeout=300s
```

---

### Issue 4: Switch Takes Too Long

**Symptom:** Traffic doesn't immediately route to new version

**Cause:** Kubernetes client cache or DNS propagation

**Solution:**
```bash
# Clear kubectl cache
kubectl config view --flatten

# Restart kubelet
minikube ssh -- docker restart $(docker ps -q)

# Or just wait - typical delay is <500ms
```

---

## 📚 Best Practices

### 1. Always Run Both Versions

```
❌ DON'T: Delete Blue before switching to Green
✅ DO: Keep both running until Green is proven stable

Reason: Instant rollback capability is blue-green's main benefit
```

### 2. Test Before Switching

```
❌ DON'T: Switch to production untested version
✅ DO: Run full test suite against Green before switch

Recommended Tests:
  ├─ Unit tests
  ├─ Integration tests
  ├─ Smoke tests
  ├─ Load tests
  └─ User acceptance tests
```

### 3. Monitor Actively After Switch

```
❌ DON'T: Switch and check later
✅ DO: Monitor continuously for 1+ hours after switch

Metrics to Monitor:
  ├─ Error rates
  ├─ Response times
  ├─ User feedback
  ├─ Database performance
  ├─ Memory usage
  └─ CPU usage
```

### 4. Have Rollback Ready

```
❌ DON'T: Shut down the old version immediately
✅ DO: Keep old version running for at least 24 hours

Why:
  ├─ Instant rollback if critical issues found
  ├─ Time to root cause any problems
  ├─ Safer than trying to re-deploy old version
```

### 5. Use Proper Versioning

```
❌ DON'T: Use :latest tag
✅ DO: Use explicit version tags

Example:
  frontend-blue:v1.0
  frontend-green:v1.1
  frontend-blue:v1.2  (after Green becomes Blue)
```

### 6. Document Changes

```
For each deployment, document:
  ├─ What changed in code
  ├─ Why the change was made
  ├─ When it was deployed
  ├─ Who approved it
  └─ Any issues encountered
```

### 7. Automate Testing

```
Deployment Pipeline:
  Code Commit
    ↓
  Build Docker Image
    ↓
  Deploy to Green
    ↓
  Run Automated Tests
    ↓
  If Pass: Switch to Green
  If Fail: Notification & Investigation
```

### 8. Plan Capacity

```
Remember:
  Both Blue and Green run simultaneously
  
  Example for 256Mi per pod, 3 replicas each:
  ├─ Blue: 3 × 256Mi = 768Mi
  ├─ Green: 3 × 256Mi = 768Mi
  └─ Total: 1.5Gi required
  
  Plan Minikube/cluster with enough resources
```

---

## 🎓 Learning Path

**Beginner (Day 1):**
1. Read this guide's Overview section
2. Run: `.\BLUE_GREEN_SWITCH.ps1 --demo`
3. Observe the automated demonstration
4. Understand the concept: two versions, switch between them

**Intermediate (Day 2):**
1. Read Architecture section
2. Read Deployment Workflow section
3. Manually make a change to Green (update HTML)
4. Rebuild Green image
5. Trigger an update: `kubectl rollout restart deployment/frontend-green`
6. Switch using: `.\BLUE_GREEN_SWITCH.ps1 --green`
7. Observe and monitor the switch

**Advanced (Day 3+):**
1. Implement CI/CD pipeline with automatic testing
2. Set up monitoring and alerting
3. Create automated rollback triggers
4. Implement canary deployments (gradual traffic shift)
5. Integrate with your existing deployment system

---

## 📞 Support Commands

Quick reference for common tasks:

```powershell
# What's currently active?
wsl kubectl get service frontend-router-service -n bluegreen -o jsonpath='{.spec.selector.version}'

# Are both versions healthy?
wsl kubectl get pods -n bluegreen --show-labels | grep version

# How many pods are in each version?
wsl kubectl get deployment -n bluegreen

# Test both versions
curl.exe http://localhost:3001/health  # Blue via router
curl.exe http://localhost:3004/health  # Green direct

# Switch to Green
.\BLUE_GREEN_SWITCH.ps1 --green

# Switch to Blue
.\BLUE_GREEN_SWITCH.ps1 --blue

# Show current state
.\BLUE_GREEN_SWITCH.ps1 --status
```

---

## 🎉 Conclusion

Blue-Green Deployment provides a reliable, safe method to update production applications with zero downtime and instant rollback capability. This implementation in Kubernetes makes it easy to manage multiple versions and switch between them instantly.

**Key Takeaways:**
✅ Two full environments (Blue & Green) running simultaneously
✅ Simple Kubernetes service selector change to switch traffic
✅ Zero downtime on traffic switch (< 100ms)
✅ Instant rollback if issues detected
✅ Both versions share backend (MongoDB) and APIs
✅ Powerful yet simple to understand and operate

**Further Reading:**
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Blue-Green Deployments (AWS Guide)](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/welcome.html)
- [Deployment Patterns (Martin Fowler)](https://martinfowler.com/bliki/BlueGreenDeployment.html)

---



BLUE_GREEN_SWITCH.ps1       ← Switch traffic
VERIFY_BLUE_GREEN.ps1       ← Verify health


DOCUMENTATION.md            ← Master guide
DEPLOYMENT_STRATEGY.md      ← NEW: Simplified approach
BLUE_GREEN_UNDERSTANDING.md ← One-page reference
BLUE_GREEN_COMMANDS.md      ← All kubectl commands
BLUE_GREEN_STRATEGY.md      ← Deep dive (optional)
QUICK_START.md              ← Setup guide
SIMPLIFICATION_SUMMARY.md   ← NEW: This summary


1. Read: doc/QUICK_START.md (30 min)
2. Run: .\VERIFY_BLUE_GREEN.ps1
✅ Done!


1. Manual port-forward or read doc/BLUE_GREEN_COMMANDS.md
2. Run: .\BLUE_GREEN_SWITCH.ps1 --green
3. Run: .\VERIFY_BLUE_GREEN.ps1
✅ Done!

When Troubleshooting:

1. Copy command from doc/BLUE_GREEN_COMMANDS.md
2. Run in PowerShell (see actual output)
3. Understand what's happening
✅ Transparent!

**Last Updated:** June 2026  
**Version:** 2.0  
**Status:** Production Ready  
