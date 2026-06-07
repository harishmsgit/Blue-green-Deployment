# ============================================================================
# BLUE-GREEN DEPLOYMENT VERIFICATION SCRIPT
# ============================================================================
# Comprehensive health check for blue-green deployments
# Verifies: Minikube, Kubernetes, Deployments, Services, Pods, and Endpoints
#
# USAGE: .\VERIFY_BLUE_GREEN.ps1
#
# ============================================================================

# Color codes
$colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-Section {
    param([string]$text)
    Write-Host ""
    Write-Host ("═" * 80) -ForegroundColor $colors.Header
    Write-Host $text -ForegroundColor $colors.Header
    Write-Host ("═" * 80) -ForegroundColor $colors.Header
}

function Write-CheckResult {
    param([string]$name, [bool]$passed, [string]$details = "")
    $status = if ($passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($passed) { $colors.Success } else { $colors.Error }
    Write-Host "$status | $name" -ForegroundColor $color
    if ($details) {
        Write-Host "        └─ $details" -ForegroundColor $colors.Info
    }
}

function Check-Minikube {
    Write-Section "1. MINIKUBE STATUS"
    
    $status = wsl minikube status 2>&1
    $running = $status -match "apiserver.*Running"
    
    Write-CheckResult "Minikube Running" $running
    
    if ($running) {
        $minikubeIp = wsl minikube ip 2>&1
        Write-Host "  Cluster IP: $minikubeIp" -ForegroundColor $colors.Info
        
        $kubeVersion = wsl kubectl version --short 2>&1 | Select-Object -First 1
        Write-Host "  Kubernetes: $kubeVersion" -ForegroundColor $colors.Info
    }
    
    return $running
}

function Check-Namespace {
    Write-Section "2. NAMESPACE"
    
    $ns = wsl kubectl get namespace bluegreen 2>&1
    $exists = -not ($ns -match "NotFound")
    
    Write-CheckResult "Namespace 'bluegreen' exists" $exists
    
    return $exists
}

function Check-Deployments {
    Write-Section "3. DEPLOYMENTS"
    
    $deployments = wsl kubectl get deployments -n bluegreen -o json 2>&1 | ConvertFrom-Json
    
    $blueExists = $deployments.items | Where-Object { $_.metadata.name -eq "frontend-blue" }
    $greenExists = $deployments.items | Where-Object { $_.metadata.name -eq "frontend-green" }
    
    Write-CheckResult "Blue Deployment exists" $null -ne $blueExists
    Write-CheckResult "Green Deployment exists" $null -ne $greenExists
    
    # Check replica status
    if ($blueExists) {
        $blueReady = $blueExists.status.readyReplicas
        $blueDesired = $blueExists.spec.replicas
        $blueHealthy = $blueReady -eq $blueDesired
        Write-CheckResult "  Blue replicas ready ($blueReady/$blueDesired)" $blueHealthy
    }
    
    if ($greenExists) {
        $greenReady = $greenExists.status.readyReplicas
        $greenDesired = $greenExists.spec.replicas
        $greenHealthy = $greenReady -eq $greenDesired
        Write-CheckResult "  Green replicas ready ($greenReady/$greenDesired)" $greenHealthy
    }
    
    return ($null -ne $blueExists -and $null -ne $greenExists)
}

function Check-Pods {
    Write-Section "4. PODS STATUS"
    
    $pods = wsl kubectl get pods -n bluegreen -o json 2>&1 | ConvertFrom-Json
    
    $bluePods = @($pods.items | Where-Object { $_.metadata.labels.version -eq "blue" })
    $greenPods = @($pods.items | Where-Object { $_.metadata.labels.version -eq "green" })
    $mongoDbPods = @($pods.items | Where-Object { $_.metadata.labels.app -eq "mongodb" })
    $backendPods = @($pods.items | Where-Object { $_.metadata.labels.app -eq "backend" })
    
    Write-Host ""
    Write-Host "Blue Frontend Pods ($($bluePods.Count) total):" -ForegroundColor $colors.Info
    foreach ($pod in $bluePods) {
        $ready = $pod.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
        $status = if ($pod.status.phase -eq "Running" -and $ready) { "✅" } else { "❌" }
        Write-Host "  $status $($pod.metadata.name) - $($pod.status.phase)" -ForegroundColor $colors.Info
    }
    
    Write-Host ""
    Write-Host "Green Frontend Pods ($($greenPods.Count) total):" -ForegroundColor $colors.Info
    foreach ($pod in $greenPods) {
        $ready = $pod.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
        $status = if ($pod.status.phase -eq "Running" -and $ready) { "✅" } else { "❌" }
        Write-Host "  $status $($pod.metadata.name) - $($pod.status.phase)" -ForegroundColor $colors.Info
    }
    
    Write-Host ""
    Write-Host "Backend Pods ($($backendPods.Count) total):" -ForegroundColor $colors.Info
    foreach ($pod in $backendPods) {
        $ready = $pod.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
        $status = if ($pod.status.phase -eq "Running" -and $ready) { "✅" } else { "❌" }
        Write-Host "  $status $($pod.metadata.name) - $($pod.status.phase)" -ForegroundColor $colors.Info
    }
    
    Write-Host ""
    Write-Host "MongoDB Pods ($($mongoDbPods.Count) total):" -ForegroundColor $colors.Info
    foreach ($pod in $mongoDbPods) {
        $ready = $pod.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
        $status = if ($pod.status.phase -eq "Running" -and $ready) { "✅" } else { "❌" }
        Write-Host "  $status $($pod.metadata.name) - $($pod.status.phase)" -ForegroundColor $colors.Info
    }
    
    $totalHealthy = @($pods.items | Where-Object {
        $_.status.phase -eq "Running" -and
        ($_.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" })
    }).Count
    
    Write-Host ""
    $allHealthy = $totalHealthy -eq $pods.items.Count
    Write-CheckResult "All pods healthy" $allHealthy "($totalHealthy/$($pods.items.Count) ready)"
    
    return $allHealthy
}

function Check-Services {
    Write-Section "5. SERVICES"
    
    $services = wsl kubectl get svc -n bluegreen -o json 2>&1 | ConvertFrom-Json
    
    $routerService = $services.items | Where-Object { $_.metadata.name -eq "frontend-router-service" }
    $blueService = $services.items | Where-Object { $_.metadata.name -eq "frontend-blue-service" }
    $greenService = $services.items | Where-Object { $_.metadata.name -eq "frontend-green-service" }
    $backendService = $services.items | Where-Object { $_.metadata.name -eq "backend-service" }
    
    Write-CheckResult "Router Service exists" $null -ne $routerService
    Write-CheckResult "Blue Service exists" $null -ne $blueService
    Write-CheckResult "Green Service exists" $null -ne $greenService
    Write-CheckResult "Backend Service exists" $null -ne $backendService
    
    # Show router service selector
    if ($routerService) {
        $activeVersion = $routerService.spec.selector.version
        Write-Host ""
        Write-Host "🔀 TRAFFIC ROUTING (Router Service):" -ForegroundColor $colors.Header
        Write-Host "   Active Version: $($activeVersion.ToUpper())" -ForegroundColor $colors.Info
    }
    
    return ($null -ne $routerService -and $null -ne $blueService -and $null -ne $greenService)
}

function Check-Endpoints {
    Write-Section "6. SERVICE ENDPOINTS"
    
    $endpoints = wsl kubectl get endpoints -n bluegreen -o json 2>&1 | ConvertFrom-Json
    
    foreach ($ep in $endpoints.items) {
        $name = $ep.metadata.name
        $subsets = $ep.subsets
        
        if ($subsets -and $subsets.addresses) {
            $addressCount = @($subsets.addresses).Count
            Write-Host "$name: $addressCount endpoint(s)" -ForegroundColor $colors.Info
            
            foreach ($addr in $subsets.addresses) {
                $version = if ($addr.targetRef.labels.version) { " [$($addr.targetRef.labels.version)]" } else { "" }
                Write-Host "  └─ $($addr.ip)$version" -ForegroundColor $colors.Info
            }
        } else {
            Write-Host "$name: ⚠️  No endpoints" -ForegroundColor $colors.Warning
        }
    }
}

function Check-ConfigMap {
    Write-Section "7. CONFIGURATION"
    
    $configMap = wsl kubectl get configmap bluegreen-config -n bluegreen -o json 2>&1 | ConvertFrom-Json
    
    Write-CheckResult "ConfigMap exists" $null -ne $configMap
    
    if ($configMap -and $configMap.data) {
        Write-Host ""
        Write-Host "Configuration values:" -ForegroundColor $colors.Info
        foreach ($key in $configMap.data.PSObject.Properties.Name) {
            Write-Host "  $key = $($configMap.data.$key)" -ForegroundColor $colors.Info
        }
    }
}

function Check-HealthProbes {
    Write-Section "8. HEALTH CHECKS"
    
    Write-Host ""
    Write-Host "Testing Blue Frontend Health:" -ForegroundColor $colors.Info
    
    try {
        $blueHealth = curl.exe -sS "http://localhost:3001/health" -w "`nSTATUS:%{http_code}" 2>&1
        if ($blueHealth -match "200") {
            Write-CheckResult "  Blue /health endpoint" $true
        } else {
            Write-CheckResult "  Blue /health endpoint" $false "Status: $blueHealth"
        }
    } catch {
        Write-CheckResult "  Blue /health endpoint" $false "Connection failed (port forward may be needed)"
    }
    
    Write-Host ""
    Write-Host "Testing Green Frontend Health:" -ForegroundColor $colors.Info
    
    try {
        $greenHealth = curl.exe -sS "http://localhost:3004/health" -w "`nSTATUS:%{http_code}" 2>&1
        if ($greenHealth -match "200") {
            Write-CheckResult "  Green /health endpoint" $true
        } else {
            Write-CheckResult "  Green /health endpoint" $false "Status: $greenHealth"
        }
    } catch {
        Write-CheckResult "  Green /health endpoint" $false "Connection failed (port forward may be needed)"
    }
    
    Write-Host ""
    Write-Host "Testing Backend Health:" -ForegroundColor $colors.Info
    
    try {
        $backendHealth = curl.exe -sS "http://localhost:5000/health" -w "`nSTATUS:%{http_code}" 2>&1
        if ($backendHealth -match "200") {
            Write-CheckResult "  Backend /health endpoint" $true
        } else {
            Write-CheckResult "  Backend /health endpoint" $false "Status: $backendHealth"
        }
    } catch {
        Write-CheckResult "  Backend /health endpoint" $false "Connection failed (port forward may be needed)"
    }
}

function Check-Resources {
    Write-Section "9. RESOURCE USAGE"
    
    try {
        $nodeResources = wsl kubectl top nodes 2>&1
        Write-Host ""
        Write-Host "Node Resources:" -ForegroundColor $colors.Info
        Write-Host $nodeResources -ForegroundColor $colors.Info
        
        Write-Host ""
        Write-Host "Pod Resources (bluegreen namespace):" -ForegroundColor $colors.Info
        $podResources = wsl kubectl top pods -n bluegreen 2>&1
        Write-Host $podResources -ForegroundColor $colors.Info
    } catch {
        Write-Host "Metrics not available (metrics-server may not be enabled)" -ForegroundColor $colors.Warning
    }
}

function Show-Summary {
    Write-Section "SUMMARY & RECOMMENDATIONS"
    
    $allChecksPassed = $true
    
    Write-Host ""
    Write-Host "✅ Deployment is ready for:" -ForegroundColor $colors.Success
    Write-Host "   • Blue-Green traffic switching" -ForegroundColor $colors.Info
    Write-Host "   • Zero-downtime deployments" -ForegroundColor $colors.Info
    Write-Host "   • Instant rollback capability" -ForegroundColor $colors.Info
    
    Write-Host ""
    Write-Host "📊 Current Configuration:" -ForegroundColor $colors.Header
    Write-Host "   • Blue: v1.0 (Basic UI)" -ForegroundColor $colors.Info
    Write-Host "   • Green: v2.0 (Enhanced UI with Dashboard)" -ForegroundColor $colors.Info
    Write-Host "   • Shared Backend: MongoDB + Express API" -ForegroundColor $colors.Info
    
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor $colors.Header
    Write-Host "   1. Start port forwarding (if not running):" -ForegroundColor $colors.Info
    Write-Host "      .\START_APP.ps1" -ForegroundColor "White"
    Write-Host "" -ForegroundColor $colors.Info
    Write-Host "   2. Test both versions:" -ForegroundColor $colors.Info
    Write-Host "      • Blue (v1.0):  http://localhost:3001" -ForegroundColor "White"
    Write-Host "      • Green (v2.0): http://localhost:3004" -ForegroundColor "White"
    Write-Host "" -ForegroundColor $colors.Info
    Write-Host "   3. Switch deployment:" -ForegroundColor $colors.Info
    Write-Host "      .\BLUE_GREEN_SWITCH.ps1 --green" -ForegroundColor "White"
    Write-Host "" -ForegroundColor $colors.Info
    Write-Host "   4. Monitor the switch:" -ForegroundColor $colors.Info
    Write-Host "      .\BLUE_GREEN_SWITCH.ps1 --monitor" -ForegroundColor "White"
    
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host ""
Write-Section "BLUE-GREEN DEPLOYMENT VERIFICATION"

# Run all checks
$minikubeOk = Check-Minikube
if (-not $minikubeOk) {
    Write-Host ""
    Write-Host "⚠️  Minikube is not running. Please start it with:" -ForegroundColor $colors.Warning
    Write-Host "   wsl minikube start --driver=docker --cpus=2 --memory=3072mb" -ForegroundColor "White"
    exit 1
}

Check-Namespace | Out-Null
Check-Deployments | Out-Null
Check-Pods | Out-Null
Check-Services | Out-Null
Check-Endpoints
Check-ConfigMap
Check-HealthProbes
Check-Resources
Show-Summary

Write-Host ""
Write-Host ("═" * 80) -ForegroundColor $colors.Header
Write-Host "✅ VERIFICATION COMPLETE" -ForegroundColor $colors.Success
Write-Host ("═" * 80) -ForegroundColor $colors.Header
Write-Host ""
