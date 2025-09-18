#!/bin/bash

# ===============================================
# Déploiement Docker Frontend / Backend sur EC2
# ===============================================

# Clé SSH
SSH_KEY="$HOME/.ssh/devops2.pem"

# Instances
FRONTEND_INSTANCES=("15.237.115.46" "51.44.217.43")
BACKEND_INSTANCES=("51.44.203.84" "13.39.104.246")

# Images Docker
FRONTEND_IMAGE="426941767449.dkr.ecr.eu-west-3.amazonaws.com/frontend-app:latest"
BACKEND_IMAGE="426941767449.dkr.ecr.eu-west-3.amazonaws.com/backend-app:latest"

# Fonction pour déployer un container
deploy_container() {
    local IP=$1
    local NAME=$2
    local IMAGE=$3
    local PORT=$4
    local CONTAINER_PORT=$5

    echo "==> Déploiement $NAME sur $IP"

    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@$IP <<EOF
sudo docker stop $NAME 2>/dev/null
sudo docker rm $NAME 2>/dev/null
sudo docker run -d -p $PORT:$CONTAINER_PORT --name $NAME $IMAGE
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
EOF
    echo ""
}

# ===============================================
# Déployer Frontend
# ===============================================
for IP in "${FRONTEND_INSTANCES[@]}"; do
    deploy_container "$IP" "frontend" "$FRONTEND_IMAGE" 80 80
done

# ===============================================
# Déployer Backend
# ===============================================
for IP in "${BACKEND_INSTANCES[@]}"; do
    deploy_container "$IP" "backend" "$BACKEND_IMAGE" 5000 8000
done
#!/bin/bash

# ===============================================
# Déploiement Docker Frontend / Backend sur EC2
# ===============================================

# Clé SSH
SSH_KEY="$HOME/.ssh/devops2.pem"

# Instances
FRONTEND_INSTANCES=("IP_FRONTEND_2")
BACKEND_INSTANCES=("IP_BACKEND_2")

# Images Docker
FRONTEND_IMAGE="426941767449.dkr.ecr.eu-west-3.amazonaws.com/frontend-app:latest"
BACKEND_IMAGE="426941767449.dkr.ecr.eu-west-3.amazonaws.com/backend-app:latest"

# Fonction pour déployer un container
deploy_container() {
    local IP=$1
    local NAME=$2
    local IMAGE=$3
    local PORT=$4
    local CONTAINER_PORT=$5

    echo "==> Déploiement $NAME sur $IP"

    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@$IP <<EOF
sudo docker stop $NAME 2>/dev/null
sudo docker rm $NAME 2>/dev/null
sudo docker run -d -p $PORT:$CONTAINER_PORT --name $NAME $IMAGE
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
EOF
    echo ""
}

# ===============================================
# Déployer Frontend
# ===============================================
for IP in "${FRONTEND_INSTANCES[@]}"; do
    deploy_container "$IP" "frontend" "$FRONTEND_IMAGE" 80 80
done

# ===============================================
# Déployer Backend
# ===============================================
for IP in "${BACKEND_INSTANCES[@]}"; do
    deploy_container "$IP" "backend" "$BACKEND_IMAGE" 5000 8000
done
