#!/bin/bash

# ========================================
# Variables à configurer
# ========================================
REGION="eu-west-3"

FRONTEND_TG="arn:aws:elasticloadbalancing:eu-west-3:426941767449:targetgroup/AWS-IaC-React-Monito-frtg/24d0446d9041a48a"
BACKEND_TG="arn:aws:elasticloadbalancing:eu-west-3:426941767449:targetgroup/AWS-IaC-React-Monito-betg/0690d1c77c526315"

FRONTEND_LB="AWS-IaC-React-Monito-frlb-1163085529.eu-west-3.elb.amazonaws.com"
BACKEND_LB="AWS-IaC-React-Monito-belb-659257707.eu-west-3.elb.amazonaws.com:5000"

# Liste des EC2 publiques (tu peux remplir dynamiquement via AWS CLI si tu veux)
FRONTEND_EC2=("15.237.115.46" "51.44.217.43")
BACKEND_EC2=("51.44.203.84" "13.39.104.246")

# ========================================
# Vérification Target Groups
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
# Vérification Load Balancers
# ========================================
test_lb() {
    local LB_URL=$1
    local NAME=$2
    echo -e "\n=== Test Load Balancer : $NAME ==="
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$LB_URL")
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "$NAME répond correctement : StatusCode $HTTP_CODE"
    else
        echo "$NAME : ERREUR - StatusCode $HTTP_CODE"
    fi
}

# ========================================
# Vérification Docker sur chaque EC2
# ========================================
check_docker_containers() {
    local EC2_IPS=("$@")
    for IP in "${EC2_IPS[@]}"; do
        echo -e "\n=== Vérification conteneurs sur EC2 $IP ==="
        ssh -o StrictHostKeyChecking=no ubuntu@"$IP" "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
    done
}

# ========================================
# Exécution des vérifications
# ========================================
check_tg_health "$FRONTEND_TG" "Frontend"
check_tg_health "$BACKEND_TG" "Backend"

test_lb "$FRONTEND_LB" "Frontend LB"
test_lb "$BACKEND_LB" "Backend LB"

echo -e "\n=== Vérification des conteneurs Docker Frontend ==="
check_docker_containers "${FRONTEND_EC2[@]}"

echo -e "\n=== Vérification des conteneurs Docker Backend ==="
check_docker_containers "${BACKEND_EC2[@]}"
