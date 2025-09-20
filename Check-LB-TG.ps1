# ===============================
# Variables
# ===============================
$FrontendLB = "http://<FRONTEND_LB_DNS>"    # Remplace par ton DNS ALB frontend
$BackendLB  = "http://<BACKEND_LB_DNS>:5000" # Remplace par ton DNS ALB backend

$FrontendTG = "arn:aws:elasticloadbalancing:eu-west-3:426941767449:targetgroup/AWS-IaC-React-Monito-frtg/24d0446d9041a48a"
$BackendTG  = "arn:aws:elasticloadbalancing:eu-west-3:426941767449:targetgroup/AWS-IaC-React-Monito-betg/0690d1c77c526315"

$HealthPaths = @("/health","/status","/ping")
$MaxTries = 5

# ===============================
# Fonction de test LB HTTP
# ===============================
function Test-LB($Name, $URL) {
    Write-Host "=== Test $Name ==="

    # Test HTTP simple
    for ($i=1; $i -le $MaxTries; $i++) {
        try {
            $resp = Invoke-WebRequest -Uri $URL -UseBasicParsing -TimeoutSec 5
            if ($resp.StatusCode -eq 200) {
                Write-Host "✅ $Name répond correctement (HTTP 200)"
                $httpStatus = "OK"
                break
            } else {
                Write-Host "⚠ Tentative $i : StatusCode $($resp.StatusCode)"
            }
        } catch {
            Write-Host "⚠ Tentative $i : Échec connexion"
        }
        Start-Sleep -Seconds 2
    }

    if (-not $httpStatus) { $httpStatus = "KO" }

    # Test endpoint santé
    $healthOk = $false
    foreach ($path in $HealthPaths) {
        try {
            $resp = Invoke-WebRequest -Uri ($URL + $path) -UseBasicParsing -TimeoutSec 5
            if ($resp.StatusCode -eq 200) {
                Write-Host "✅ Endpoint santé ($path)"
                $healthOk = $true
                break
            }
        } catch {}
    }
    if (-not $healthOk) { Write-Host "❌ Aucun endpoint santé valide trouvé ($($HealthPaths -join ' '))" }

    return [PSCustomObject]@{
        Name   = $Name
        HTTP   = $httpStatus
        HEALTH = if($healthOk){ "OK" } else { "KO" }
    }
}

# ===============================
# Vérifier Target Groups
# ===============================
function Check-TG($Name, $TGArn) {
    Write-Host "`n=== Vérification Target Group $Name ==="
    try {
        aws elbv2 describe-target-health --target-group-arn $TGArn --query 'TargetHealthDescriptions[*].{ID:Target.Id,State:TargetHealth.State}' --output table
    } catch {
        Write-Host "❌ Impossible de récupérer l'état du Target Group"
    }
}

# ===============================
# Exécution des tests
# ===============================
Check-TG "Frontend" $FrontendTG
Check-TG "Backend" $BackendTG

$FrontendResult = Test-LB "Frontend LB" $FrontendLB
$BackendResult  = Test-LB "Backend LB"  $BackendLB

# ===============================
# Résumé global
# ===============================
Write-Host "`n=== Résumé global ==="
Write-Host "Frontend LB : HTTP=$($FrontendResult.HTTP), HEALTH=$($FrontendResult.HEALTH)"
Write-Host "Backend LB  : HTTP=$($BackendResult.HTTP), HEALTH=$($BackendResult.HEALTH)"
Write-Host "===================="
