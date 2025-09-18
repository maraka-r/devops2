# ==========================
# Variables à modifier
# ==========================
$awsProfile  = "new-account"                  # Ton profil AWS
$awsRegion   = "eu-west-3"                    # Région AWS
$accountId   = "426941767449"                 # Ton AWS Account ID
$repoName    = "test-repo"                    # Nom du repository ECR
$imageName   = "my-app"                        # Nom de l'image Docker
$imageTag    = "latest"                        # Tag de l'image
$projectPath = "C:\Dossier pro\frontend"      # Chemin de ton projet React

# Dossier temporaire pour build léger
$tmpBuildPath = "C:\tmp\docker-build"

# ==========================
# 1. Créer le dossier temporaire
# ==========================
if (Test-Path $tmpBuildPath) { Remove-Item $tmpBuildPath -Recurse -Force }
New-Item -Path $tmpBuildPath -ItemType Directory | Out-Null

# ==========================
# 2. Copier uniquement les fichiers essentiels
# ==========================
$filesToCopy = @("package.json","package-lock.json")
$dirsToCopy  = @("src","public")

foreach ($file in $filesToCopy) {
    Copy-Item -Path (Join-Path $projectPath $file) -Destination $tmpBuildPath
}

foreach ($dir in $dirsToCopy) {
    Copy-Item -Path (Join-Path $projectPath $dir) -Destination $tmpBuildPath -Recurse
}

# Copier le Dockerfile minimal
Copy-Item -Path (Join-Path $projectPath "Dockerfile") -Destination $tmpBuildPath

# ==========================
# 3. Build l'image Docker
# ==========================
Write-Host "[INFO] Build Docker image..."
docker build -t "${imageName}:${imageTag}" $tmpBuildPath
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Build échoué"; exit 1 }

# ==========================
# 4. Login à AWS ECR
# ==========================
Write-Host "[INFO] Login AWS ECR..."
aws ecr get-login-password --region $awsRegion --profile $awsProfile | `
    docker login --username AWS --password-stdin "${accountId}.dkr.ecr.${awsRegion}.amazonaws.com"
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Login ECR échoué"; exit 1 }

# ==========================
# 5. Tag et push l'image
# ==========================
$ecrImage = "${accountId}.dkr.ecr.${awsRegion}.amazonaws.com/${repoName}:${imageTag}"
docker tag "${imageName}:${imageTag}" $ecrImage
docker push $ecrImage

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Image poussée sur ECR : $ecrImage"
} else {
    Write-Host "[ERROR] Push échoué"
}
