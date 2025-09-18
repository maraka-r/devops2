#!/bin/bash

# ========================================
# Variables à configurer
# ========================================
REGION="eu-west-3"

FRONTEND_TG="arn:aws:elasticloadbalancing:eu-west-3:426941767449:targetgroup/AWS-IaC-React-Monito-frtg/24d0446d9041a48a"
BACKEND_TG="arn:aws:elasticloadbalancing:eu-west-3:426941767449:targetgroup/AWS-IaC-React-Monito-betg/0690d1c77c526315"

FRONTEND_LB="AWS-IaC-React-Monito-frlb-1163085529.eu-west-3.elb.amazonaws.com"
BACKEND_LB="AWS-IaC-React-Monito-belb-659257707.eu-west-3.elb.amazonaws.com:5000"

# ========================================
# Fonction pour vérifier la santé des Target Groups
# ========================================
check_tg_health() {
    local TG_ARN=$1
    local NAME=$2

    echo -e "\n=== Vérification Target Group : $NAME ==="
    aws elbv2 describe-target-health \
        --target-group-arn "$TG_ARN" \
        --region "$REGION" \
        --query 'TargetHealthDescriptions[*].{ID:Target.Id,State:TargetHealth.State}' \
        --output table
}

# ========================================
# Fonction pour tester les Load Balancers
# ========================================
test_lb() {
    local LB_URL=$1
    local NAME=$2

    echo -e "\n=== Test Load Balancer : $NAME ==="
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$LB_URL)
    if [ "$HTTP_CODE" == "000" ]; then
        echo "$NAME : ERREUR - impossible de se connecter"
    else
        echo "$NAME répond : HTTP $HTTP_CODE"
    fi
}

# ========================================
# Récupération des IP publiques EC2
# ========================================
echo -e "\n=== Récupération des IP publiques EC2 ==="

FRONTEND_IPS=$(aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:Name,Values=frontend" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text)

BACKEND_IPS=$(aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:Name,Values=backend" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text)

echo "Frontend EC2 IPs : $FRONTEND_IPS"
echo "Backend EC2 IPs  : $BACKEND_IPS"

# ========================================
# Vérification Target Groups
# ========================================
check_tg_health "$FRONTEND_TG" "Frontend"
check_tg_health "$BACKEND_TG" "Backend"

# ========================================
# Test Load Balancers
# ========================================
test_lb "$FRONTEND_LB" "Frontend LB"
test_lb "$BACKEND_LB" "Backend LB"

# ========================================
# Vérification conteneurs Docker
# ========================================
echo -e "\n=== Vérification des conteneurs Docker ==="
sudo docker ps -a

echo -e "\n=== Test connectivité conteneurs localement ==="

for CONTAINER in $(sudo docker ps -q); do
    NAME=$(sudo docker inspect --format='{{.Name}}' $CONTAINER | sed 's/^\///')
    echo -e "\nContainer: $NAME"

    # Récupérer tous les ports exposés et les tester
    PORTS=$(sudo docker inspect --format='{{json .NetworkSettings.Ports}}' $CONTAINER | jq -r 'to_entries[] | select(.value != null) | .value[0].HostPort')
    if [ -z "$PORTS" ]; then
        echo "Aucun port exposé"
        continue
    fi

    for PORT in $PORTS; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)
        echo "Port $PORT répond : HTTP $HTTP_CODE"
    done
done
