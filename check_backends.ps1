# ==============================================
# check_backends.ps1 - mise à jour automatique du backend
# ==============================================

# Variables
$Region = "eu-west-3"
$TagFilter = "AWS-IaC-React-Monitoring-backend-*"
$KeyPath = "C:\Users\laoua\.ssh\devops2.pem"
$LocalBackendDir = "C:\Dossier pro\backend"
$RemoteBackendDir = "/home/ubuntu/backend"
$AppName = "backend-app"
$ContainerName = "backend"
$PortHost = 5000
$PortContainer = 8000

Write-Host "Récupération des instances backend..."

# Récupération des instances
$Instances = aws ec2 describe-instances `
    --region $Region `
    --filters "Name=tag:Name,Values=$TagFilter" `
    --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]" `
    --output json | ConvertFrom-Json

foreach ($reservation in $Instances) {
    foreach ($instance in $reservation) {
        $InstanceId = $instance[0]
        $PublicIP = $instance[1]
        $State = $instance[2]

        Write-Host "========================================"
        Write-Host "Instance ID  : $InstanceId"
        Write-Host "Public IP    : $PublicIP"
        Write-Host "State        : $State"

        if (-not $PublicIP) {
            Write-Host "Pas d'IP publique, skip"
            continue
        }

        # Crée le répertoire backend si nécessaire
        Write-Host "Création du répertoire backend sur l'instance..."
        ssh -o StrictHostKeyChecking=no -i $KeyPath ubuntu@$PublicIP "mkdir -p $RemoteBackendDir"

        # Copie des fichiers backend
        Write-Host "Copie des fichiers backend..."
        scp -o StrictHostKeyChecking=no -i $KeyPath -r "${LocalBackendDir}/*" "ubuntu@${PublicIP}:$RemoteBackendDir/"

        # Build et relance du conteneur Docker
        Write-Host "Build et relance du conteneur Docker..."
        $sshScript = @"
cd $RemoteBackendDir
docker build -t $($AppName.ToLower()) .
sudo docker stop $ContainerName 2>/dev/null || true
sudo docker rm $ContainerName 2>/dev/null || true
sudo docker run -d -p $PortHost`:$PortContainer --name $ContainerName $($AppName.ToLower()):latest
"@
        ssh -o StrictHostKeyChecking=no -i $KeyPath ubuntu@$PublicIP "$sshScript"

        # Vérification de l'endpoint /health
        Write-Host "Vérification de l'endpoint /health..."
        try {
            $Health = Invoke-WebRequest -UseBasicParsing -Uri ("http://${PublicIP}:${PortHost}/health") -TimeoutSec 5
            Write-Host "/health accessible sur $PublicIP"
        } catch {
            Write-Host "/health inaccessible sur $PublicIP"
        }

        Write-Host ""
    }
}
