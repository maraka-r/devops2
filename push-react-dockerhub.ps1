# ==========================
# Variables à modifier
# ==========================
$rama402 = "ton-utilisateur-dockerhub"   # <-- Mets ton username Docker Hub
$imageName  = "my-app"
$imageTag   = "latest"

# ==========================
# 1. Vérifier Docker
# ==========================
docker info | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker n'est pas lancé."
    exit 1
}

# ==========================
# 2. Build de l'image Docker
# ==========================
Write-Host "[INFO] Construction de l'image Docker..."
docker build -t "${imageName}:${imageTag}" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Echec du build Docker."
    exit 1
}

# ==========================
# 3. Login à Docker Hub
# ==========================
Write-Host "[INFO] Connexion à Docker Hub..."
docker login

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Login Docker Hub échoué."
    exit 1
}

# ==========================
# 4. Tag pour Docker Hub
# ==========================
$dockerHubImage = "${dockerUser}/${imageName}:${imageTag}"
Write-Host "[INFO] Tagging de l'image -> $dockerHubImage"
docker tag "${imageName}:${imageTag}" $dockerHubImage

# ==========================
# 5. Push sur Docker Hub
# ==========================
Write-Host "[INFO] Push de l'image vers Docker Hub..."
docker push $dockerHubImage

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Image poussée avec succès sur Docker Hub : $dockerHubImage"
} else {
    Write-Host "[ERROR] Echec du push vers Docker Hub."
}
