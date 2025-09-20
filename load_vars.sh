#!/bin/bash
# =====================================
# Récupération automatique des variables pour CI/CD
# =====================================

REGION="eu-west-3"
PROJECT="AWS-IaC-React-Monito"
ACCOUNT_ID="426941767449"

echo "Récupération des variables pour CI/CD..."

# --- ECR Images ---
FRONTEND_ECR="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/frontend-app:latest"
BACKEND_ECR="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend-app:latest"

# --- Load Balancers ---
FRONTEND_LB=$(aws elbv2 describe-load-balancers --region $REGION \
    --query "LoadBalancers[?contains(LoadBalancerName, 'frlb')].DNSName" --output text)

BACKEND_LB=$(aws elbv2 describe-load-balancers --region $REGION \
    --query "LoadBalancers[?contains(LoadBalancerName, 'belb')].DNSName" --output text)

# --- Target Groups ---
FRONTEND_TG=$(aws elbv2 describe-target-groups --region $REGION \
    --query "TargetGroups[?contains(TargetGroupName, 'frtg')].TargetGroupArn" --output text)

BACKEND_TG=$(aws elbv2 describe-target-groups --region $REGION \
    --query "TargetGroups[?contains(TargetGroupName, 'betg')].TargetGroupArn" --output text)

# --- Instances ---
FRONTEND_INSTANCES=$(aws ec2 describe-instances --region $REGION \
    --filters "Name=tag:Name,Values=${PROJECT}-frontend-*" \
    --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

BACKEND_INSTANCES=$(aws ec2 describe-instances --region $REGION \
    --filters "Name=tag:Name,Values=${PROJECT}-backend-*" \
    --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

# --- Export variables ---
export FRONTEND_ECR BACKEND_ECR FRONTEND_LB BACKEND_LB FRONTEND_TG BACKEND_TG FRONTEND_INSTANCES BACKEND_INSTANCES

echo "Variables exportées :"
echo "FRONTEND_ECR=$FRONTEND_ECR"
echo "BACKEND_ECR=$BACKEND_ECR"
echo "FRONTEND_LB=$FRONTEND_LB"
echo "BACKEND_LB=$BACKEND_LB"
echo "FRONTEND_TG=$FRONTEND_TG"
echo "BACKEND_TG=$BACKEND_TG"
echo "FRONTEND_INSTANCES=$FRONTEND_INSTANCES"
echo "BACKEND_INSTANCES=$BACKEND_INSTANCES"
