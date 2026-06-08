# Ingress Functionality in Blue-Green Deployment

This document explains how Kubernetes Ingress works in this project, how traffic flows from the user to the application, and which commands help verify and debug the setup.

## 1. What Ingress Does

Ingress is the HTTP/HTTPS entry point for services running inside a Kubernetes cluster.

Without Ingress, you usually access the application using a NodePort service:

```bash
curl http://localhost:3001/api/users
curl http://localhost:3004/api/users
```

With Ingress, you can access the application using a clean host name and path:

```bash
curl http://bluegreen.local/api/users
```

Ingress does not run by itself. It needs an Ingress Controller, such as NGINX Ingress Controller, to actually receive traffic and route it.

In Minikube, the controller is usually enabled with:

```bash
minikube addons enable ingress
```

## 2. High-Level Architecture

```text
User / Browser / curl
        |
        v
Host name, for example bluegreen.local
        |
        v
Minikube IP / Ingress Controller
        |
        v
Kubernetes Ingress rule
        |
        v
Kubernetes Service
        |
        v
Application Pods
        |
        v
MongoDB Service
        |
        v
MongoDB Pod / StatefulSet
```

In blue-green deployment, the important part is this:

```text
Ingress -> Service -> Blue Pods
```

or:

```text
Ingress -> Service -> Green Pods
```

Ingress normally stays the same. The service decides whether traffic goes to blue or green pods.

## 3. Blue-Green Traffic Flow

### Current Active Version

If blue is active:

```text
User
  |
  v
bluegreen.local/api/users
  |
  v
Ingress Controller
  |
  v
Ingress rule
  |
  v
Application Service
  |
  v
Pods with version=blue
```

If green is active:

```text
User
  |
  v
bluegreen.local/api/users
  |
  v
Ingress Controller
  |
  v
Ingress rule
  |
  v
Application Service
  |
  v
Pods with version=green
```

The Ingress rule points to the service. The service selector controls which pods receive the traffic.

Example service selector for blue:

```yaml
selector:
  app: bluegreen-app
  version: blue
```

Example service selector for green:

```yaml
selector:
  app: bluegreen-app
  version: green
```

## 4. Why Ingress Is Useful Here

Ingress gives one stable endpoint for the application.

Instead of asking users to change URLs when switching between blue and green versions, users keep calling the same URL:

```bash
curl http://bluegreen.local/api/users
```

Behind the scenes, Kubernetes routes that request to whichever version is currently active.

This makes blue-green switching cleaner:

```text
Before switch:
bluegreen.local -> Service -> Blue Pods

After switch:
bluegreen.local -> Service -> Green Pods
```

## 5. Required Minikube Setup

Enable the ingress addon:

```bash
minikube addons enable ingress
```

Verify that the NGINX ingress controller is running:

```bash
kubectl get pods -n ingress-nginx
```

Expected result:

```text
ingress-nginx-controller-xxxxx   1/1   Running
```

Get the Minikube IP:

```bash
minikube ip
```

Example:

```text
192.168.49.2
```

## 6. Hostname Setup

If the ingress host is `bluegreen.local`, your local machine needs to know that this host points to the Minikube IP.

Edit `/etc/hosts` in WSL/Linux:

```bash
sudo nano /etc/hosts
```

Add this line:

```text
<minikube-ip> bluegreen.local
```

Example:

```text
192.168.49.2 bluegreen.local
```

You can also add it with one command:

```bash
echo "$(minikube ip) bluegreen.local" | sudo tee -a /etc/hosts
```

Now test DNS resolution:

```bash
ping bluegreen.local
```

## 7. Apply Ingress Manifest

Apply the ingress YAML file:

```bash
kubectl apply -f kubernetes/07-ingress.yaml
```

Check ingress:

```bash
kubectl get ingress -n bluegreen
```

Describe ingress:

```bash
kubectl describe ingress -n bluegreen
```

The describe output shows:

- Host name
- Path rules
- Backend service
- Backend service port
- Events or errors

## 8. Test Application Through Ingress

Test health endpoint:

```bash
curl http://bluegreen.local/health
```

Test users endpoint:

```bash
curl http://bluegreen.local/api/users
```

Register a user:

```bash
curl -X POST http://bluegreen.local/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"pass123"}'
```

Fetch users again:

```bash
curl http://bluegreen.local/api/users
```

## 9. Verify Which Version Is Receiving Traffic

Check services:

```bash
kubectl get svc -n bluegreen
```

Check pods:

```bash
kubectl get pods -n bluegreen --show-labels
```

Check endpoints:

```bash
kubectl get endpoints -n bluegreen
```

Endpoints show which pod IPs are connected to the service. If the active service points to blue pods, the endpoint IPs should match blue pods. If it points to green pods, they should match green pods.

Get pod IPs:

```bash
kubectl get pods -n bluegreen -o wide
```

Compare the pod IPs with:

```bash
kubectl get endpoints -n bluegreen
```

## 10. Blue-Green Switch Flow

The normal switch flow is:

```text
1. Deploy blue version.
2. Service points to blue pods.
3. Ingress sends traffic to the service.
4. Users access blue through ingress.
5. Deploy green version.
6. Test green directly or through a preview service.
7. Change service selector from blue to green.
8. Ingress still points to the same service.
9. Users now reach green through the same URL.
```

Before switch:

```text
bluegreen.local -> Ingress -> Service -> Blue Pods
```

After switch:

```text
bluegreen.local -> Ingress -> Service -> Green Pods
```

## 11. Important Debug Commands

Check ingress controller:

```bash
kubectl get pods -n ingress-nginx
```

Check ingress object:

```bash
kubectl get ingress -n bluegreen
kubectl describe ingress -n bluegreen
```

Check services:

```bash
kubectl get svc -n bluegreen
kubectl describe svc -n bluegreen
```

Check pods:

```bash
kubectl get pods -n bluegreen
kubectl get pods -n bluegreen -o wide
kubectl get pods -n bluegreen --show-labels
```

Check service endpoints:

```bash
kubectl get endpoints -n bluegreen
```

Check application logs:

```bash
kubectl logs -n bluegreen <app-pod-name>
```

Check MongoDB logs:

```bash
kubectl logs -n bluegreen mongodb-0
```

Check events:

```bash
kubectl get events -n bluegreen --sort-by=.metadata.creationTimestamp
```

## 12. Common Problems and Fixes

### Problem: `curl http://bluegreen.local/api/users` does not work

Check if ingress controller is running:

```bash
kubectl get pods -n ingress-nginx
```

Check if hostname is mapped:

```bash
cat /etc/hosts
```

Confirm Minikube IP:

```bash
minikube ip
```

Fix `/etc/hosts`:

```bash
echo "$(minikube ip) bluegreen.local" | sudo tee -a /etc/hosts
```

### Problem: Ingress exists but backend is not reachable

Check service:

```bash
kubectl get svc -n bluegreen
kubectl describe svc -n bluegreen
```

Check endpoints:

```bash
kubectl get endpoints -n bluegreen
```

If endpoints are empty, the service selector does not match any running pod labels.

Check pod labels:

```bash
kubectl get pods -n bluegreen --show-labels
```

### Problem: Wrong version is receiving traffic

Check service selector:

```bash
kubectl describe svc -n bluegreen
```

Check pod labels:

```bash
kubectl get pods -n bluegreen --show-labels
```

The selector should match only the active version.

### Problem: API works through NodePort but not through Ingress

This means the app is probably working, but ingress routing or hostname mapping has an issue.

Check:

```bash
kubectl describe ingress -n bluegreen
kubectl get pods -n ingress-nginx
cat /etc/hosts
```

## 13. Quick Checklist

Use this checklist when testing ingress:

```text
1. Namespace exists.
2. App pods are running.
3. MongoDB pod is running.
4. Services exist.
5. Service endpoints are not empty.
6. Ingress controller is running.
7. Ingress resource exists.
8. Hostname is mapped to Minikube IP.
9. curl to ingress host works.
10. Active service points to the correct blue or green pods.
```

## 14. Useful One-Time Test Sequence

```bash
minikube addons enable ingress
kubectl apply -f kubernetes/07-ingress.yaml
kubectl get pods -n ingress-nginx
kubectl get ingress -n bluegreen
kubectl describe ingress -n bluegreen
echo "$(minikube ip) bluegreen.local" | sudo tee -a /etc/hosts
curl http://bluegreen.local/health
curl http://bluegreen.local/api/users
```

## 15. Final Summary

Ingress gives your blue-green deployment one stable external URL.

The traffic path is:

```text
User -> Ingress Controller -> Ingress Rule -> Service -> Active Pods -> MongoDB
```

During blue-green switching, the user-facing URL does not change. The Kubernetes service changes which pods receive traffic.

## 16. Post-Patch Ingress Sync and Verification

Use this section after editing `kubernetes/07-ingress.yaml`.

In this project, `bluegreen.local` was added to the ingress rules so requests like this can match a backend:

```bash
curl -H "Host: bluegreen.local" http://localhost:8888/api/users
```

Without a matching host rule, NGINX Ingress can be reachable but still return:

```text
404 Not Found
nginx
```

That means the request reached the ingress controller, but no ingress rule matched the host and path.

### Step 1: Apply the Updated Ingress YAML

Run this from the project root:

```bash
kubectl apply -f kubernetes/07-ingress.yaml
```

Expected result:

```text
ingress.networking.k8s.io/bluegreen-ingress configured
```

If it says `created`, that is also fine. It means the ingress did not exist earlier and has now been created.

### Step 2: Confirm the Ingress Exists

```bash
kubectl get ingress -n bluegreen
```

You should see:

```text
bluegreen-ingress
```

### Step 3: Confirm the Host and Paths

```bash
kubectl describe ingress bluegreen-ingress -n bluegreen
```

Check that the output contains `bluegreen.local`.

Expected routing:

```text
bluegreen.local
  /api    -> backend-service:5000
  /health -> backend-service:5000
  /       -> frontend-blue-service:3001
```

This confirms that ingress knows how to route `bluegreen.local` requests.

### Step 4: Check the Ingress Controller

```bash
kubectl get pods -n ingress-nginx
```

Expected result:

```text
ingress-nginx-controller-xxxxx   1/1   Running
```

Also check the ingress controller service:

```bash
kubectl get svc -n ingress-nginx
```

In this setup, the controller service may be `NodePort`, for example:

```text
ingress-nginx-controller   NodePort   ...   80:30884/TCP,443:31084/TCP
```

### Step 5: Start Port Forwarding

If direct access to the Minikube IP times out from WSL, use port-forwarding.

Start this in one terminal:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8888:80
```

Keep this terminal open.

Expected result:

```text
Forwarding from 127.0.0.1:8888 -> 80
Forwarding from [::1]:8888 -> 80
```

If port `8888` is already in use, choose another port:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 9999:80
```

Then replace `8888` with `9999` in the test commands.

### Step 6: Test the API Through Ingress

In another terminal:

```bash
curl -v -H "Host: bluegreen.local" http://localhost:8888/api/users
```

This verifies:

```text
localhost:8888 -> ingress-nginx-controller -> bluegreen.local /api rule -> backend-service:5000
```

If it works, the ingress API route is correct.

### Step 7: Test the Health Route

```bash
curl -v -H "Host: bluegreen.local" http://localhost:8888/health
```

This verifies:

```text
localhost:8888 -> ingress-nginx-controller -> bluegreen.local /health rule -> backend-service:5000
```

### Step 8: Test User Registration Through Ingress

```bash
curl -X POST http://localhost:8888/api/register \
  -H "Host: bluegreen.local" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"pass123"}'
```

Then fetch users:

```bash
curl -H "Host: bluegreen.local" http://localhost:8888/api/users
```

### Step 9: Check Backend Service and Endpoints

If the ingress route works but the app does not respond correctly, check the backend service:

```bash
kubectl get svc -n bluegreen
kubectl describe svc backend-service -n bluegreen
```

Check endpoints:

```bash
kubectl get endpoints backend-service -n bluegreen
```

If endpoints are empty, the service selector is not matching any backend pods.

Check pod labels:

```bash
kubectl get pods -n bluegreen --show-labels
```

### Step 10: Check Application Logs

Get pods:

```bash
kubectl get pods -n bluegreen
```

Check backend logs:

```bash
kubectl logs -n bluegreen <backend-pod-name>
```

If the API route reaches the backend, you should see logs related to the request.

### Step 11: Check MongoDB Data

Connect to MongoDB:

```bash
kubectl exec -it mongodb-0 -n bluegreen -- mongosh "mongodb://admin:mongopass@localhost:27017/bluegreen?authSource=admin"
```

Inside `mongosh`:

```javascript
show dbs
show collections
db.users.find().pretty()
```

If no users are shown, search all databases for user collections:

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

### Step 12: Full Post-Patch Checklist

```text
1. kubectl apply completed successfully.
2. bluegreen-ingress exists in namespace bluegreen.
3. bluegreen.local is listed in ingress rules.
4. /api routes to backend-service:5000.
5. /health routes to backend-service:5000.
6. / routes to frontend-blue-service:3001.
7. ingress-nginx-controller pod is Running.
8. Port-forward is active on localhost:8888.
9. curl with Host: bluegreen.local reaches /api/users.
10. curl with Host: bluegreen.local reaches /health.
11. backend-service has endpoints.
12. backend pod logs show requests.
13. MongoDB contains registered user data.
```

### Step 13: Common Post-Patch Errors

If you get this:

```text
404 Not Found
nginx
```

The ingress controller is reachable, but the host/path rule did not match.

Check:

```bash
kubectl describe ingress bluegreen-ingress -n bluegreen
```

If you get this:

```text
Connection timed out
```

The ingress controller is not reachable from your terminal.

Use port-forward:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8888:80
```

If you get this:

```text
Connection refused
```

The local port is not listening, or the port-forward is not running.

Start port-forward again:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8888:80
```

If port `8888` is already used:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 9999:80
```
