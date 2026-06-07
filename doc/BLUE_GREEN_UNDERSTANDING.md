# 🔵🟢 BLUE-GREEN DEPLOYMENT - PRODUCTION REFERENCE

**Version:** 1.0 | **Status:** Production Ready | **Last Updated:** June 2026

## What Is It?
Two identical production environments. Blue (v1.0) OR Green (v2.0) serves traffic. When updating, deploy to idle version, test, then switch instantly (< 100ms). If issues occur, switch back immediately.

---

## Why Blue-Green?

| Traditional | Blue-Green |
|-------------|-----------|
| ❌ Downtime (30-120 min) | ✅ Zero downtime (< 100ms) |
| ❌ Hard rollback (1-2 hrs) | ✅ Instant rollback (< 100ms) |
| ❌ Limited testing time | ✅ Weeks to test before switch |
| ❌ Users see errors | ✅ Users never notice change |
| ❌ Revenue loss | ✅ No downtime = no lost revenue |

**Bottom Line:** Deploy with zero risk. Test fully. Switch instantly. Rollback if needed.

---

## Our Setup

```
Frontend Router Service (selector: version=blue or green)
          ↓
    ┌─────┴─────┐
    ↓           ↓
BLUE v1.0    GREEN v2.0
(3 pods)     (3 pods)
BASIC UI     ENHANCED UI
   ↓           ↓
    └─────┬─────┘
          ↓
   Shared Backend (2 pods)
   Shared MongoDB (1 pod)
```

**Blue (v1.0):** Simple registration form (currently active)  
**Green (v2.0):** Dashboard + user management (standby, ready to test)

---

## How It Works

**Phase 1 - Deploy:** New code deployed to idle version (Green while Blue serves users)  
**Phase 2 - Test:** Thoroughly test Green with no production impact  
**Phase 3 - Switch:** Change router selector from blue→green (< 100ms, zero downtime)  
**Phase 4 - Monitor:** Watch Green for 1-6 hours. If stable, done.  
**Phase 5 - Rollback:** If issues found, switch back to Blue immediately (< 100ms)

```
BEFORE SWITCH:           AFTER SWITCH:           IF ROLLBACK:
Blue ACTIVE ✅          Green ACTIVE ✅         Blue ACTIVE ✅
Green standby ⏸️         Blue standby ⏸️         Green standby ⏸️
(all traffic)           (all traffic)           (all traffic)
```

---

## Quick Commands

| Task | Command |
|------|---------|
| **Start** | `.\START_APP.ps1` (opens port forwarding) |
| **Verify** | `.\VERIFY_BLUE_GREEN.ps1` (health check) |
| **Switch to Green** | `.\BLUE_GREEN_SWITCH.ps1 --green` |
| **Switch to Blue** | `.\BLUE_GREEN_SWITCH.ps1 --blue` |
| **Check Status** | `.\BLUE_GREEN_SWITCH.ps1 --status` |
| **Interactive Menu** | `.\BLUE_GREEN_SWITCH.ps1` |
| **Watch Pods** | `wsl kubectl get pods -n bluegreen -w` |
| **Test Blue** | `curl.exe http://localhost:3001/health` |
| **Test Green** | `curl.exe http://localhost:3004/health` |

---

## Deployment Workflow

1. **Edit Code** → frontend-green/public/index.html
2. **Build Image** → `docker build -t blue-green-deployment-frontend-green:latest ./frontend-green`
3. **Restart Pods** → `kubectl rollout restart deployment/frontend-green -n bluegreen`
4. **Test Green** → http://localhost:3004 (while Blue serves users)
5. **Switch** → `.\BLUE_GREEN_SWITCH.ps1 --green`
6. **Monitor** → Watch logs for 1-2 hours
7. **Done** → Green is now production, Blue is backup

---

## 📋 DEPLOYMENT CHECKLIST

### Before Switching to Green

- [ ] Green pods are 1/1 Ready
- [ ] Green /health endpoint responds
- [ ] All features tested in Green
- [ ] Load testing completed
- [ ] Security validation passed
- [ ] Database compatibility verified
- [ ] API response times acceptable
- [ ] Error rates are 0%
- [ ] Blue still stable (no unrelated issues)

### After Switching to Green

- [ ] Monitor error rates (next 1 hour)
- [ ] Monitor response times
- [ ] Check user feedback channels
- [ ] Verify database performance
- [ ] Confirm no data corruption
- [ ] After 6+ hours, declare stable
- [ ] After 24 hours, can retire Blue

### Before Retiring Old Version

- [ ] Green has run stable for 24+ hours
- [ ] Zero issues reported
- [ ] Rollback no longer needed
- [ ] Then: kubectl delete deployment frontend-blue

---

## 🔐 WHEN TO USE BLUE-GREEN

### ✅ Perfect For

- Critical production applications
- Applications with SLA (uptime guarantees)
- Teams wanting zero-downtime deployments
- Deployments requiring extensive validation
- High-traffic applications
- Applications with strict compliance needs

### ⚠️ Not Ideal For

- Resource-constrained environments (both versions running simultaneously)
- Applications with large database migrations
- Applications updated hourly or more frequently
- Single-pod applications (waste of resources)
- Environments where resource costs are critical concern

---

## 💰 COST ANALYSIS

### Infrastructure Cost

Both versions run simultaneously:
- **Memory:** 2x application memory footprint
- **CPU:** 2x application CPU footprint
- **Storage:** Shared database (no duplication)

**Example Costs:**
- Single version: 2 CPUs, 2Gi RAM = $100/month
- Blue-Green: 4 CPUs, 4Gi RAM = $200/month
- **Cost Increase:** $100/month for zero-downtime capability

### ROI (Return on Investment)

**Hour of Downtime Costs:**
- E-commerce: $5,600 - $225,000 per hour
- SaaS: $300 - $150,000 per hour
- FPre-Switch Checklist

- [ ] Green pods are 1/1 Ready
- [ ] Green /health endpoint responds  
- [ ] All features tested in Green
- [ ] No errors in Green logs
- [ ] Blue still stable
- [ ] Database compatible with both versions
**Q: What if Green has bugs?**  
A: Switch back to Blue instantly (< 100ms). Fix Green and retry.

**Q: What if both versions have issues?**  
A: Keep old Blue version for another 24 hours as backup.

**Q: Does downtime happen during switch?**  
A: No. Switch happens in < 100ms. Users won't notice.

**Q: Can users see both versions?**  
A: No. All traffic routes to one active version. Users see consistent experience.

**Q: What if database needs migration?**  
A: Both versions must support old AND new schema. Migrate before switching.

**Q: Can we test Green with real user traffic?**  
A: Yes! Keep Blue active, send mirror traffic to Green using load balancing.

**Q: How long should we keep both versions running?**  
A: Keep for 24-48 hours minimum. If Green stable, can retire Blue after.

**Q: What's the simplest implementation?**  
A: Exactly what you have: Service selector + manual switch. No complex tools needed.

---

## 🎓 LEARNING PATH

### For Developers
1. Read this document (you are here)
2. Run: `.\BLUE_GREEN_SWITCH.ps1 --demo`
3. Make a change to Green
4. Switch and observe
5. Experiment with features

### For DevOps
1. Study BLUE_GREEN_STRATEGY.md
2. Review kubernetes manifests
3. Understand service selector mechanism
4. Plan monitoring strategy
5. Create alerting rules

### For Managers
1. Read: Cost Analysis section (above)
2. Understand: ROI benefits
3. Note: No maintenance windows scheduled
4. Plan: Team training on procedures

---

## 📞 SUPPORT & TROUBLESHOOTING

### If selector doesn't change:
```bash
kubectl get service frontend-router-service -n bluegreen -o yaml | grep -A2 "selector:"
```

### If pods won't start:
```bash
kubectl describe pod <pod-name> -n bluegreen
kubectl logs <pod-name> -n bluegreen
```

### If traffic still routes to old version:
```bash
kubectl delete service frontend-router-service -n bluegreen
kubectl apply -f kubernetes/08-frontend-router-service.yaml
```

### For detailed help:
See: `BLUE_GREEN_STRATEGY.md` (complete guide)  
Or: `BLUE_GREEN_COMMANDS.md` (command reference)

---

## ✅ CONCLUSION
Key Points

| Aspect | Details |
|--------|---------|
| **Downtime** | Zero (< 100ms switch) |
| **Rollback** | Instant (1 command) |
| **Testing** | Full parallel testing possible |
| **Cost** | Both versions running = 2x resources |
| **Mechanism** | Kubernetes service selector |
| **Risk** | Minimal (instant rollback always ready) |

---

## FAQ

**Q: Does switch cause downtime?**  
A: No. < 100ms, users won't notice.

**Q: Can we rollback quickly?**  
A: Yes. Instantly (< 100ms) back to previous version.

**Q: What if new version has bugs?**  
A: Switch back to Blue immediately. No impact to users.

**Q: How long should we keep both versions?**  
A: 24-48 hours minimum. Blue is instant fallback.

**Q: Do both versions share data?**  
A: Yes. Shared MongoDB database. All user data persists.

---

## Files Reference

| File | Purpose |
|------|---------|
| `BLUE_GREEN_SWITCH.ps1` | Traffic switching script |
| `VERIFY_BLUE_GREEN.ps1` | Health checks |
| `kubernetes/08-frontend-router-service.yaml` | Router service |
| `BLUE_GREEN_STRATEGY.md` | Detailed guide (if needed) |
| `BLUE_GREEN_COMMANDS.md` | Command reference (if needed) |

---

## Status

✅ **Production Ready** | ✅ **Zero Downtime Verified** | ✅ **Instant Rollback Ready*