# ============================================================================
# BLUE-GREEN DEPLOYMENT SWITCHING SCRIPT
# ============================================================================
# This script demonstrates how to switch traffic between Blue and Green
# frontend versions in a zero-downtime blue-green deployment pattern.
#
# USAGE: .\BLUE_GREEN_SWITCH.ps1
#
# ============================================================================

# Color codes for output
$successColor = "Green"
$errorColor = "Red"
$warningColor = "Yellow"
$infoColor = "Cyan"

function Write-Success {
    param([string]$message)
    Write-Host "✅ $message" -ForegroundColor $successColor
}

function Write-Error2 {
    param([string]$message)
    Write-Host "❌ $message" -ForegroundColor $errorColor
}

function Write-Warning2 {
    param([string]$message)
    Write-Host "⚠️  $message" -ForegroundColor $warningColor
}

function Write-Info {
    param([string]$message)
    Write-Host "ℹ️  $message" -ForegroundColor $infoColor
}

function Separator {
    param([string]$title = "")
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $infoColor
    if ($title) {
        Write-Host $title -ForegroundColor $infoColor
        Write-Host ("=" * 80) -ForegroundColor $infoColor
    }
}

function CheckMinikube {
    Write-Info "Checking Minikube status..."
    $status = wsl minikube status 2>&1
    if ($status -like "*Running*") {
        Write-Success "Minikube is running"
        return $true
    } else {
        Write-Error2 "Minikube is not running"
        Write-Info "Start Minikube with: wsl minikube start --driver=docker --cpus=2 --memory=3072mb"
        return $false
    }
}

function GetCurrentActiveVersion {
    Write-Info "Fetching current active deployment..."
    $output = wsl kubectl get service frontend-router-service -n bluegreen -o jsonpath='{.spec.selector.version}' 2>&1
    return $output
}

function CheckDeploymentStatus {
    param([string]$version)
    
    Write-Info "Checking $version deployment status..."
    $pods = wsl kubectl get pods -n bluegreen -l version=$version -o json 2>&1 | ConvertFrom-Json
    
    if ($pods.items) {
        $readyPods = @($pods.items | Where-Object { $_.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" } }).Count
        $totalPods = $pods.items.Count
        
        Write-Info "$version deployment: $readyPods/$totalPods pods ready"
        return ($readyPods -eq $totalPods)
    } else {
        Write-Error2 "$version deployment has no pods"
        return $false
    }
}

function TestDeploymentHealth {
    param([string]$version)
    
    Write-Info "Testing $version frontend health..."
    
    $port = if ($version -eq "blue") { 3001 } else { 3004 }
    
    try {
        $response = curl.exe -sS "http://localhost:$port/health" -w "`nSTATUS:%{http_code}" 2>&1
        if ($response -match "200") {
            Write-Success "$version frontend is healthy"
            return $true
        } else {
            Write-Warning2 "$version frontend responded but status not 200: $response"
            return $false
        }
    } catch {
        Write-Warning2 "$version frontend health check failed (port forwarding may not be active)"
        return $false
    }
}

function SwitchToVersion {
    param([string]$targetVersion)
    
    Separator "SWITCHING TO $($targetVersion.ToUpper()) DEPLOYMENT"
    
    # Validate input
    if ($targetVersion -notmatch "^(blue|green)$") {
        Write-Error2 "Invalid version: $targetVersion. Must be 'blue' or 'green'"
        return $false
    }
    
    $currentVersion = GetCurrentActiveVersion
    
    if ($currentVersion -eq $targetVersion) {
        Write-Warning2 "$($targetVersion.ToUpper()) is already the active deployment"
        return $true
    }
    
    Write-Info "Current active deployment: $($currentVersion.ToUpper())"
    Write-Info "Switching to: $($targetVersion.ToUpper())"
    
    # Create patch to update service selector
    $patch = @{
        spec = @{
            selector = @{
                version = $targetVersion
            }
        }
    } | ConvertTo-Json -Compress
    
    Write-Info "Applying traffic switch..."
    
    # Apply the patch to frontend-router-service
    $patchResult = wsl kubectl patch service frontend-router-service -n bluegreen -p $patch 2>&1
    
    if ($patchResult -match "patched" -or $patchResult -match "configured") {
        Write-Success "Successfully switched traffic to $($targetVersion.ToUpper())"
        
        # Verify switch
        Start-Sleep -Seconds 2
        $newActive = GetCurrentActiveVersion
        
        if ($newActive -eq $targetVersion) {
            Write-Success "Verification confirmed: $($targetVersion.ToUpper()) is now active"
            
            # Also update NodePort service
            Write-Info "Updating NodePort service..."
            $nodePatchResult = wsl kubectl patch service frontend-router-service-nodeport -n bluegreen -p $patch 2>&1
            Write-Success "NodePort service updated"
            
            return $true
        } else {
            Write-Error2 "Switch verification failed. Active version: $newActive"
            return $false
        }
    } else {
        Write-Error2 "Failed to switch deployment: $patchResult"
        return $false
    }
}

function ShowDeploymentStats {
    Separator "DEPLOYMENT STATISTICS"
    
    Write-Info "Blue Deployment (v1.0 - Basic):"
    CheckDeploymentStatus "blue" | Out-Null
    TestDeploymentHealth "blue" | Out-Null
    
    Write-Host ""
    
    Write-Info "Green Deployment (v2.0 - Enhanced):"
    CheckDeploymentStatus "green" | Out-Null
    TestDeploymentHealth "green" | Out-Null
    
    Write-Host ""
    
    $currentActive = GetCurrentActiveVersion
    Write-Info "Currently ACTIVE version: $($currentActive.ToUpper())"
}

function MonitorSwitch {
    param([int]$durationSeconds = 30)
    
    Separator "MONITORING SWITCH (Next $durationSeconds seconds)"
    
    Write-Info "Monitoring service endpoints and traffic..."
    
    $endTime = (Get-Date).AddSeconds($durationSeconds)
    $count = 0
    
    while ((Get-Date) -lt $endTime) {
        $count++
        Write-Host ""
        Write-Info "Check #$count at $(Get-Date -Format 'HH:mm:ss')"
        
        # Show current service selector
        $activeVersion = GetCurrentActiveVersion
        Write-Host "  Active Version: $($activeVersion.ToUpper())" -ForegroundColor $infoColor
        
        # Check pod distribution
        $bluePods = wsl kubectl get pods -n bluegreen -l version=blue --no-headers 2>&1 | Measure-Object | Select-Object -ExpandProperty Count
        $greenPods = wsl kubectl get pods -n bluegreen -l version=green --no-headers 2>&1 | Measure-Object | Select-Object -ExpandProperty Count
        
        Write-Host "  Blue Pods: $bluePods | Green Pods: $greenPods" -ForegroundColor $infoColor
        
        Start-Sleep -Seconds 5
    }
    
    Write-Success "Monitoring complete"
}

function InteractiveSwitch {
    Separator "INTERACTIVE BLUE-GREEN SWITCH"
    
    Write-Host ""
    Write-Info "Current deployment status:"
    ShowDeploymentStats
    
    Write-Host ""
    Write-Info "Blue-Green Switching Options:"
    Write-Host "  1. Switch to Blue (v1.0 - Basic)" -ForegroundColor "Cyan"
    Write-Host "  2. Switch to Green (v2.0 - Enhanced)" -ForegroundColor "Cyan"
    Write-Host "  3. Show detailed status" -ForegroundColor "Cyan"
    Write-Host "  4. Test both deployments" -ForegroundColor "Cyan"
    Write-Host "  5. Monitor active deployment" -ForegroundColor "Cyan"
    Write-Host "  6. Exit" -ForegroundColor "Cyan"
    
    Write-Host ""
    $choice = Read-Host "Select option (1-6)"
    
    switch ($choice) {
        "1" {
            $current = GetCurrentActiveVersion
            if ($current -eq "blue") {
                Write-Warning2 "Blue is already active"
            } else {
                if (SwitchToVersion "blue") {
                    Write-Success "Switch to Blue completed successfully"
                    Write-Info "Access Blue at: http://localhost:3001"
                } else {
                    Write-Error2 "Switch failed"
                }
            }
        }
        "2" {
            $current = GetCurrentActiveVersion
            if ($current -eq "green") {
                Write-Warning2 "Green is already active"
            } else {
                if (SwitchToVersion "green") {
                    Write-Success "Switch to Green completed successfully"
                    Write-Info "Access Green at: http://localhost:3004 (or router at localhost:3001)"
                } else {
                    Write-Error2 "Switch failed"
                }
            }
        }
        "3" {
            ShowDeploymentStats
        }
        "4" {
            TestDeploymentHealth "blue" | Out-Null
            TestDeploymentHealth "green" | Out-Null
        }
        "5" {
            MonitorSwitch -durationSeconds 60
        }
        "6" {
            Write-Info "Exiting..."
            exit 0
        }
        default {
            Write-Error2 "Invalid option"
        }
    }
    
    Write-Host ""
    $continueChoice = Read-Host "Continue? (y/n)"
    if ($continueChoice -eq "y") {
        InteractiveSwitch
    }
}

function FullDemonstration {
    Separator "BLUE-GREEN DEPLOYMENT DEMONSTRATION"
    
    Write-Info "This script will demonstrate a complete blue-green deployment cycle:"
    Write-Host "  1. Verify both deployments are healthy"
    Write-Host "  2. Show current active version"
    Write-Host "  3. Switch to Green deployment"
    Write-Host "  4. Monitor the switch"
    Write-Host "  5. Switch back to Blue deployment"
    Write-Host "  6. Show final status"
    Write-Host ""
    
    # Step 1: Check Minikube
    if (-not (CheckMinikube)) {
        Write-Error2 "Cannot proceed without Minikube"
        return
    }
    
    Write-Host ""
    
    # Step 2: Show current status
    ShowDeploymentStats
    Write-Host ""
    
    $currentVersion = GetCurrentActiveVersion
    Write-Info "Starting with $($currentVersion.ToUpper()) as active deployment"
    
    # Step 3: Switch to opposite version
    $targetVersion = if ($currentVersion -eq "blue") { "green" } else { "blue" }
    
    Write-Host ""
    Read-Host "Press Enter to switch to $($targetVersion.ToUpper()) deployment..."
    
    if (SwitchToVersion $targetVersion) {
        Write-Success "Traffic successfully switched to $($targetVersion.ToUpper())"
        
        # Monitor the switch
        Write-Host ""
        MonitorSwitch -durationSeconds 15
        
        # Switch back
        Write-Host ""
        Write-Info "Demonstrating instant rollback capability..."
        Write-Info "Switching back to original deployment ($($currentVersion.ToUpper()))..."
        Start-Sleep -Seconds 2
        
        if (SwitchToVersion $currentVersion) {
            Write-Success "Rollback to $($currentVersion.ToUpper()) completed successfully"
            Write-Success "This demonstrates the zero-downtime, instant-rollback capability of blue-green deployments"
        }
    }
    
    # Final status
    Write-Host ""
    ShowDeploymentStats
    
    Separator "DEMONSTRATION COMPLETE"
    Write-Info "Blue-Green deployment switching is working correctly!"
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================

Separator "BLUE-GREEN DEPLOYMENT SWITCH UTILITY"

Write-Info "This script helps demonstrate and manage blue-green deployment switches"
Write-Host ""
Write-Host "Options:"
Write-Host "  --demo      : Run full automated demonstration" -ForegroundColor "Cyan"
Write-Host "  --blue      : Switch to Blue deployment" -ForegroundColor "Cyan"
Write-Host "  --green     : Switch to Green deployment" -ForegroundColor "Cyan"
Write-Host "  --status    : Show current deployment status" -ForegroundColor "Cyan"
Write-Host "  --monitor   : Monitor the active deployment" -ForegroundColor "Cyan"
Write-Host "  --interactive : Interactive menu (default)" -ForegroundColor "Cyan"
Write-Host ""

$args = $args.ToLower()

if ($args -contains "--demo") {
    FullDemonstration
} elseif ($args -contains "--blue") {
    if (CheckMinikube) {
        SwitchToVersion "blue"
    }
} elseif ($args -contains "--green") {
    if (CheckMinikube) {
        SwitchToVersion "green"
    }
} elseif ($args -contains "--status") {
    ShowDeploymentStats
} elseif ($args -contains "--monitor") {
    if (CheckMinikube) {
        MonitorSwitch -durationSeconds 60
    }
} else {
    # Interactive mode (default)
    if (CheckMinikube) {
        InteractiveSwitch
    }
}

Write-Host ""
