# 📚 DOCUMENTATION GUIDE

## 🎯 Which File To Use?

### FOR PRODUCTION TEAMS (Daily Use)

| File | Purpose | When to Use | Time |
|------|---------|-----------|------|
| **doc/BLUE_GREEN_UNDERSTANDING.md** | One-page reference for all teams | Quick lookup, handouts, training | 5 min |
| **doc/BLUE_GREEN_COMMANDS.md** | Copy-paste command reference | Running daily operations | 2 min |

### FOR OPERATIONS & EXECUTION

| File | Purpose | When to Use | How |
|------|---------|-----------|-----|
| **BLUE_GREEN_SWITCH.ps1** | Traffic switching script | Switch Blue ↔ Green | `.\BLUE_GREEN_SWITCH.ps1 --green` |
| **VERIFY_BLUE_GREEN.ps1** | Health verification | Validate all components | `.\VERIFY_BLUE_GREEN.ps1` |

### FOR GETTING STARTED

| File | Purpose | When to Use | Time |
|------|---------|-----------|------|
| **doc/QUICK_START.md** | Copy-paste setup guide | First-time Minikube+WSL setup | 30 min |

### FOR TECHNICAL DEEP DIVE (Optional)

| File | Purpose | When to Use | For |
|------|---------|-----------|-----|
| **doc/BLUE_GREEN_STRATEGY.md** | Detailed technical architecture | Learning the pattern in depth | Architects, tech leads |

---

## 📖 RECOMMENDED READING ORDER

### ✅ FIRST TIME SETUP
1. Read: **doc/BLUE_GREEN_UNDERSTANDING.md** (5 min) - Understand the pattern
2. Read: **doc/DEPLOYMENT_STRATEGY.md** (10 min) - Understand simplified approach
3. Execute: **doc/QUICK_START.md** (30 min) - Copy-paste setup commands
4. Verify: Run ``.\\VERIFY_BLUE_GREEN.ps1`` (2 min)

### ✅ DAILY OPERATIONS
1. Setup access: Use kubectl port-forward commands (transparent, no hidden scripts)
2. Verify health: Run ``.\\VERIFY_BLUE_GREEN.ps1``
3. Execute operation: Run ``.\\BLUE_GREEN_SWITCH.ps1 --green`` or `--blue`
4. Check logs: Copy commands from **doc/BLUE_GREEN_COMMANDS.md**

### ✅ WHEN SOMETHING BREAKS
1. Check status: Run ``.\\VERIFY_BLUE_GREEN.ps1`` - Shows exact issue
2. Copy diagnostic commands from **doc/BLUE_GREEN_COMMANDS.md**
3. Run them in PowerShell terminal (you see exactly what's happening)
4. Read **doc/BLUE_GREEN_STRATEGY.md** for root cause understanding

---

## 🗂️ DIRECTORY STRUCTURE

```
Blue-green-Deployment/
├── � doc/
│   ├── 📄 DOCUMENTATION.md                ← Master guide (you are here)
│   ├── 📄 BLUE_GREEN_UNDERSTANDING.md     ← One-page reference (START HERE)
│   ├── 📄 BLUE_GREEN_COMMANDS.md          ← Command cheat sheet
│   ├── 📄 BLUE_GREEN_STRATEGY.md          ← Deep dive (optional)
│   ├── 📄 QUICK_START.md                  ← Setup guide (30 min)
│   ├── 🔧 START_APP.ps1                   ← Auto-startup
│   ├── 🔧 QUICK_TROUBLESHOOT.ps1          ← Diagnostics
│   └── minikube-setup-logs/               ← Setup logs (reference)
│
├── 🔧 BLUE_GREEN_SWITCH.ps1               ← Switching script (root)
├── 🔧 VERIFY_BLUE_GREEN.ps1               ← Verification script (root)
│
├── kubernetes/
│   └── [7 YAML manifests for k8s deployment]
│
├── backend/
│   └── [Express API]
│
├── frontend-blue/
│   └── [v1.0 BASIC UI]
│
├── frontend-green/
│   └── [v2.0 ENHANCED UI]
│
└── docker-compose.yml
```

---

## ⚡ QUICK COMMANDS

```powershell
# First time? Run port forwarding in separate terminals
wsl kubectl port-forward -n bluegreen svc/frontend-blue-service 3001:3001
wsl kubectl port-forward -n bluegreen svc/frontend-green-service 3004:3004
wsl kubectl port-forward -n bluegreen svc/backend-service 5000:5000

# Switch to Green
.\BLUE_GREEN_SWITCH.ps1 --green

# Switch to Blue  
.\BLUE_GREEN_SWITCH.ps1 --blue

# Check status
.\BLUE_GREEN_SWITCH.ps1 --status

# Verify health
.\VERIFY_BLUE_GREEN.ps1

# Check logs (see doc/BLUE_GREEN_COMMANDS.md for more)
kubectl logs -n bluegreen -l app=backend --tail=50
```

---

## 📊 FILE SIZES & COMPLEXITY

| File | Type | Size | Complexity | For Whom |
|------|------|------|-----------|----------|
| doc/BLUE_GREEN_UNDERSTANDING.md | Reference | ~250 lines | ⭐ Simple | Everyone |
| doc/BLUE_GREEN_COMMANDS.md | Reference | ~200 lines | ⭐ Simple | Everyone |
| doc/DEPLOYMENT_STRATEGY.md | Strategy | ~300 lines | ⭐ Simple | All teams |
| doc/BLUE_GREEN_STRATEGY.md | Technical | ~400 lines | ⭐⭐⭐ Complex | Architects |
| BLUE_GREEN_SWITCH.ps1 | Script | ~400 lines | ⭐⭐ Medium | DevOps |
| VERIFY_BLUE_GREEN.ps1 | Script | ~200 lines | ⭐⭐ Medium | DevOps |
| doc/QUICK_START.md | Guide | ~300 lines | ⭐ Simple | First-timers |

---

## ✅ WHAT'S DELETED (Why - Simplification)

Removed 2 helper scripts for cleaner, more transparent approach:
- ❌ `doc/START_APP.ps1` → Users run kubectl port-forward directly (transparent, learn kubectl)
- ❌ `doc/QUICK_TROUBLESHOOT.ps1` → Commands in BLUE_GREEN_COMMANDS.md (copy-paste, transparent)
- ❌ `WSL_COMPLETE_SETUP_GUIDE.sh` → Consolidated into QUICK_START.md
- ❌ `WINDOWS_WSL_SETUP_GUIDE.ps1` → Redundant, use QUICK_START.md
- ❌ `WSL_CHECKLIST_TROUBLESHOOTING.md` → Commands in BLUE_GREEN_COMMANDS.md
- ❌ `README_GUIDES_INDEX.md` → Replaced by DOCUMENTATION.md

---

## 🎓 LEARNING PATHS

### Path A: "Just Make It Work" (30 minutes)
1. Read: doc/BLUE_GREEN_UNDERSTANDING.md (5 min)
2. Read: doc/DEPLOYMENT_STRATEGY.md (10 min) - Understand simplified approach
3. Execute: doc/QUICK_START.md commands (15 min)
4. Verify: ``.\VERIFY_BLUE_GREEN.ps1`` (2 min)
5. Open: http://localhost:3001 (Blue) and http://localhost:3004 (Green)

### Path B: "I Need to Understand Everything" (1 hour)
1. Read: doc/BLUE_GREEN_UNDERSTANDING.md
2. Read: doc/DEPLOYMENT_STRATEGY.md (this file - the simplified approach)
3. Execute: doc/QUICK_START.md commands manually
4. Manually run kubectl port-forward commands (learn kubectl)
5. Run: ``.\BLUE_GREEN_SWITCH.ps1 --demo``
6. Review: kubernetes/ manifest files

### Path C: "I'm Building the CI/CD Pipeline" (2 hours)
1. Complete Path B above
2. Read: doc/BLUE_GREEN_STRATEGY.md (deep technical details)
3. Study: BLUE_GREEN_SWITCH.ps1 and VERIFY_BLUE_GREEN.ps1 (the 2 core scripts)
4. Create custom wrapper scripts around these 2 scripts
5. Integrate kubectl commands into your CI/CD system

---

## 🆘 NEED HELP?

| Issue | Do This |
|-------|----------|
| "Is everything running?" | Run ``.\VERIFY_BLUE_GREEN.ps1`` (health check) |
| "How do I switch traffic?" | Run ``.\BLUE_GREEN_SWITCH.ps1 --green`` |
| "Where are my commands?" | Open `doc/BLUE_GREEN_COMMANDS.md` |
| "What is blue-green?" | Read `doc/BLUE_GREEN_UNDERSTANDING.md` |
| "Why is it failing?" | Copy-paste command from `doc/BLUE_GREEN_COMMANDS.md` and run it |
| "How should I deploy?" | Read `doc/DEPLOYMENT_STRATEGY.md` |
| "Deep dive into architecture?" | Read `doc/BLUE_GREEN_STRATEGY.md` |

---

**Last Updated:** June 2026  
**Status:** Production Ready ✅  
**Deployments:** 2 (Blue v1.0 + Green v2.0)  
**Switching:** Zero-downtime via kubectl service selector
