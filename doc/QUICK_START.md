# QUICK START - COPY & PASTE FOR WSL

# ============================================================================
# ONE-TIME SETUP (Run in WSL terminal)
# ============================================================================

# Step 1: Update and install
sudo apt update && sudo apt upgrade -y

# Step 2: Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker

# Step 3: Install Minikube
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Step 4: Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

# ============================================================================
# START CLUSTER (Run once each day)
# ============================================================================
minikube delete --all --purge
minikube start --driver=docker --cpus=2 --memory=3072 --disk-size=20gb
minikube status
minikube addons enable metrics-server
minikube addons enable ingress

# ============================================================================
# BUILD AND DEPLOY (First time only)
# ============================================================================

# Build images in Minikube
eval $(minikube docker-env)
cd ~/HeroVired/Assignment5/Blue-green-Deployment
docker compose build

# Deploy to Kubernetes
cd kubernetes
chmod +x deploy.sh
./deploy.sh

# ============================================================================
# VERIFY DEPLOYMENT
# ============================================================================

kubectl get pods -n bluegreen
kubectl get svc -n bluegreen
kubectl get pods -n bluegreen -w

# ============================================================================
# ACCESS FROM WINDOWS (Option A: NodePort - EASIEST)
# ============================================================================

# Get the IP
minikube ip

# Open browser:
# Blue: http://<IP>:30001
# Green: http://<IP>:30004

# ============================================================================
# ACCESS FROM WINDOWS (Option B: Port Forwarding)
# ============================================================================
If you prefer localhost access, you can run:

# Terminal 1
harish@Harish:/mnt/d/HeroVired/Assignment5/Blue-green-Deployment/kubernetes$ minikube service frontend-blue-service -n bluegreen
┌───────────┬───────────────────────┬─────────────┬───────────────────────────┐
│ NAMESPACE │         NAME          │ TARGET PORT │            URL            │
├───────────┼───────────────────────┼─────────────┼───────────────────────────┤
│ bluegreen │ frontend-blue-service │ http/3001   │ http://192.168.49.2:30001 │
└───────────┴───────────────────────┴─────────────┴───────────────────────────┘
🔗  Starting tunnel for service frontend-blue-service.
┌───────────┬───────────────────────┬─────────────┬────────────────────────┐
│ NAMESPACE │         NAME          │ TARGET PORT │          URL           │
├───────────┼───────────────────────┼─────────────┼────────────────────────┤
│ bluegreen │ frontend-blue-service │             │ http://127.0.0.1:39293 │
└───────────┴───────────────────────┴─────────────┴───

# Terminal 2 (new window/tab)
harish@Harish:/mnt/d/HeroVired/Assignment5/Blue-green-Deployment/kubernetes$ minikube service frontend-green-service -n bluegreen
┌───────────┬────────────────────────┬─────────────┬───────────────────────────┐
│ NAMESPACE │          NAME          │ TARGET PORT │            URL            │
├───────────┼────────────────────────┼─────────────┼───────────────────────────┤
│ bluegreen │ frontend-green-service │ http/3004   │ http://192.168.49.2:30004 │
└───────────┴────────────────────────┴─────────────┴───────────────────────────┘
🔗  Starting tunnel for service frontend-green-service.
┌───────────┬────────────────────────┬─────────────┬────────────────────────┐
│ NAMESPACE │          NAME          │ TARGET PORT │          URL           │
├───────────┼────────────────────────┼─────────────┼────────────────────────┤
│ bluegreen │ frontend-green-service │             │ http://127.0.0.1:38759 │
└───────────┴────────────────────────┴─────────────┴────────────────────────┘
🎉  Opening service bluegreen/frontend-green-service in default browser...
👉  http://127.0.0.1:38759
❗  Because you are using a Docker driver on linux, the terminal needs to be open to run it.

# Terminal 3 (new window/tab)
kubectl port-forward -n bluegreen svc/backend-service 5000:5000

# Then from Windows:
# Blue: http://localhost:3001
# Green: http://localhost:3004
# Backend: http://localhost:5000

# ============================================================================
# TEST THE APP (From WSL or Windows)
# ============================================================================

# Test health
curl http://localhost:3001/health
curl http://localhost:3004/health
curl http://localhost:5000/health

# Register user
curl -X POST http://localhost:3004/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"pass123"}'

# Get all users
curl http://localhost:5000/api/users

# Check MongoDB
kubectl exec -it -n bluegreen mongodb-0 -- mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin"
# In mongosh: db.users.find().pretty()

# ============================================================================
# VIEW LOGS
# ============================================================================

# Backend logs
kubectl logs -n bluegreen -l app=backend --tail=50

# MongoDB logs
kubectl logs -n bluegreen -l app=mongodb --tail=50

# Blue frontend logs
kubectl logs -n bluegreen -l version=blue --tail=50

# Green frontend logs
kubectl logs -n bluegreen -l version=green --tail=50

# Follow logs in real-time
kubectl logs -n bluegreen -l app=backend -f

# ============================================================================
# SCALE DEPLOYMENTS
# ============================================================================

kubectl scale deployment backend --replicas=3 -n bluegreen
kubectl scale deployment frontend-blue --replicas=3 -n bluegreen
kubectl scale deployment frontend-green --replicas=3 -n bluegreen

# Check scaling
kubectl get deployment -n bluegreen

# ============================================================================
# UPDATE DEPLOYMENT (After code changes)
# ============================================================================

# Rebuild images
eval $(minikube docker-env)
docker compose build

# Restart services
kubectl rollout restart deployment/backend -n bluegreen
kubectl rollout restart deployment/frontend-blue -n bluegreen
kubectl rollout restart deployment/frontend-green -n bluegreen

# Monitor update
kubectl rollout status deployment/backend -n bluegreen -w

# ============================================================================
# STOP AND CLEANUP
# ============================================================================

# Delete everything
kubectl delete namespace bluegreen

# Stop Minikube (keeps data)
minikube stop

# Delete Minikube (loses data)
minikube delete

# ============================================================================
# HELPFUL ALIASES (Add to ~/.bashrc)
# ============================================================================

alias mk-start='minikube start --driver=docker --cpus=4 --memory=4096'
alias mk-stop='minikube stop'
alias mk-ip='minikube ip'
alias kgp='kubectl get pods -n bluegreen'
alias kgs='kubectl get svc -n bluegreen'
alias kl='kubectl logs -n bluegreen'

# Then use:
# mk-start
# kgp
# mk-ip

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

# Pods stuck in Pending?
kubectl describe pod <POD_NAME> -n bluegreen

# Pod crashing?
kubectl logs -n bluegreen <POD_NAME>
kubectl logs -n bluegreen <POD_NAME> --previous

# Service not found?
kubectl get endpoints -n bluegreen
kubectl describe svc backend-service -n bluegreen

# Need more resources?
minikube stop
minikube start --driver=docker --cpus=6 --memory=6144

# Check cluster health
minikube status
kubectl cluster-info
kubectl get nodes

# ============================================================================
# WINDOWS POWERSHELL QUICK COMMANDS
# ============================================================================

# Get Minikube IP
$IP = wsl minikube ip
Write-Host "Access at: http://$IP:30001"

# Open frontends
$IP = wsl minikube ip
Start-Process "http://$IP:30001"
Start-Process "http://$IP:30004"

# Check pods
wsl kubectl get pods -n bluegreen

# View logs
wsl kubectl logs -n bluegreen -l app=backend -f

# Register test user from Windows
$IP = wsl minikube ip
curl.exe -X POST "http://$IP:30004/api/register" `
  -H "Content-Type: application/json" `
  -d '{"name":"Windows User","email":"win@test.com","password":"pass"}'

# ============================================================================
# COMPLETE WORKFLOW CHECKLIST
# ============================================================================

□ Install prerequisites in WSL (Docker, Minikube, kubectl)
□ Start Minikube cluster (minikube start)
□ Build Docker images (docker compose build)
□ Deploy to Kubernetes (./deploy.sh)
□ Verify all pods running (kubectl get pods -n bluegreen)
□ Get Minikube IP (minikube ip)
□ Open browser to Blue/Green frontends
□ Test registration via frontend
□ Verify data in MongoDB
□ Scale deployments if needed
□ Test rolling updates
□ Stop cluster when done (minikube stop)

# ============================================================================
# KEEP TERMINAL WINDOWS OPEN FOR PORT FORWARDING
# ============================================================================

# If using port forwarding, keep these running:
# Terminal 1: kubectl port-forward -n bluegreen svc/frontend-blue-service 3001:3001
# Terminal 2: kubectl port-forward -n bluegreen svc/frontend-green-service 3004:3004
# Terminal 3: kubectl port-forward -n bluegreen svc/backend-service 5000:5000
# Terminal 4: For testing/commands

# Or use NodePort instead (easier - no need for port forwarding):
# Just access http://<minikube-ip>:30001 and http://<minikube-ip>:30004

# ============================================================================
