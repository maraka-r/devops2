# ==========================
# Variables à modifier
# ==========================
$dockerUser   = "rama402"                 # <-- Mets ton username Docker Hub
$imageName    = "my-app"
$imageTag     = "latest"
$projectPath  = "C:\Dossier pro\frontend"

# Utiliser ${} pour éviter l'erreur avec ":"
$dockerHubImage = "${dockerUser}/${imageName}:${imageTag}"

# Dossier temporaire pour build
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
# 3. Build de l'image Docker
# ==========================
Write-Host "[INFO] Build Docker image..."
docker build -t "${imageName}:${imageTag}" $tmpBuildPath
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Build échoué"; exit 1 }

# ==========================
# 4. Login à Docker Hub
# ==========================
Write-Host "[INFO] Login Docker Hub..."
docker login
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Login échoué"; exit 1 }

# ==========================
# 5. Tag et push l'image
# ==========================
docker tag "${imageName}:${imageTag}" $dockerHubImage
docker push $dockerHubImage

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Image poussée sur Docker Hub : $dockerHubImage"
} else {
    Write-Host "[ERROR] Push échoué"
}
