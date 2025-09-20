#!/bin/bash

# Variables
TG_ARN="arn:aws:elasticloadbalancing:eu-west-3:426941767449:targetgroup/AWS-IaC-React-Monito-betg/0690d1c77c526315"
REGION="eu-west-3"
BACKEND_LB="AWS-IaC-React-Monito-belb-659257707.eu-west-3.elb.amazonaws.com"

echo "=== Vérification du port du Target Group Backend ==="
PORT=$(aws elbv2 describe-target-groups \
  --target-group-arns $TG_ARN \
  --region $REGION \
  --query 'TargetGroups[0].Port' \
  --output text)

echo "Port actuel du TG Backend : $PORT"

# Si le port n'est pas 5000, on le modifie
if [ "$PORT" -ne 5000 ]; then
  echo "⚠️  Le port n'est pas 5000, mise à jour en cours..."
  aws elbv2 modify-target-group \
    --target-group-arn $TG_ARN \
    --port 5000 \
    --protocol HTTP \
    --region $REGION
  echo "✅ Port mis à jour sur 5000"
else
  echo "✅ Le port est déjà configuré sur 5000"
fi

echo ""
echo "=== Vérification de la santé des instances Backend ==="
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region $REGION \
  --query 'TargetHealthDescriptions[*].{ID:Target.Id,Port:Target.Port,State:TargetHealth.State}' \
  --output table

echo ""
echo "=== Test direct du Load Balancer Backend ==="
for i in {1..5}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$BACKEND_LB:5000 || echo "000")
  echo "Tentative $i : StatusCode $STATUS"
  if [ "$STATUS" -eq 200 ]; then
    echo "✅ Backend LB est accessible sur http://$BACKEND_LB:5000"
    exit 0
  fi
  sleep 5
done

echo "❌ Backend LB n'a pas répondu correctement après 5 tentatives"
exit 1
