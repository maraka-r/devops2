#!/bin/bash

# ===============================
# Configuration des Load Balancers
# ===============================
FRONTEND_LB="AWS-IaC-React-Monito-frlb-1163085529.eu-west-3.elb.amazonaws.com"
BACKEND_LB="AWS-IaC-React-Monito-belb-659257707.eu-west-3.elb.amazonaws.com:5000"

# Endpoints santé possibles
HEALTH_PATHS=("/health" "/status" "/ping")

# ===============================
# Fonction de test LB
# ===============================
test_lb() {
    LB_NAME=$1
    LB_URL=$2

    echo "=== Test $LB_NAME ==="

    # Test HTTP principal
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$LB_URL)
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "Connexion HTTP : ✅ $HTTP_CODE"
    else
        echo "Connexion HTTP : ❌ $HTTP_CODE"
    fi

    # Test endpoints santé
    HEALTH_OK=0
    for path in "${HEALTH_PATHS[@]}"; do
        CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$LB_URL$path)
        if [ "$CODE" -eq 200 ]; then
            echo "Endpoint santé ($path) : ✅ OK"
            HEALTH_OK=1
            break
        fi
    done

    if [ "$HEALTH_OK" -eq 0 ]; then
        echo "Endpoint santé : ❌ Aucun chemin valide trouvé (${HEALTH_PATHS[*]})"
    fi

    echo ""
}

# ===============================
# Lancer les tests
# ===============================
test_lb "Frontend LB" $FRONTEND_LB
test_lb "Backend LB" $BACKEND_LB

echo "=== Fin des tests ==="
