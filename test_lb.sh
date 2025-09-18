#!/bin/bash

# URLs des load balancers
FRONTEND_LB_URL="http://AWS-IaC-React-Monito-frlb-1163085529.eu-west-3.elb.amazonaws.com"
BACKEND_LB_URL="http://AWS-IaC-React-Monito-belb-659257707.eu-west-3.elb.amazonaws.com"

# Liste des endpoints santé possibles
HEALTH_PATHS=("/health" "/status" "/ping")

function tester_lb() {
    LB_NAME=$1
    LB_URL=$2

    echo "=== Vérification $LB_NAME ==="

    # Test de connexion HTTP
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $LB_URL)
    if [ "$HTTP_CODE" == "000" ]; then
        echo "Connexion HTTP : ❌ Échec (StatusCode 000)"
        HTTP_STATUS="KO"
    else
        echo "Connexion HTTP : $HTTP_CODE ✅"
        HTTP_STATUS="OK"
    fi

    # Test DNS
    echo "Test DNS..."
    DNS_RESULT=$(nslookup $(echo $LB_URL | awk -F/ '{print $3}') 2>/dev/null)
    if echo "$DNS_RESULT" | grep -q "Addresses:"; then
        echo "Résolution DNS : ✅ OK"
        DNS_STATUS="OK"
    else
        echo "Résolution DNS : ❌ KO"
        DNS_STATUS="KO"
    fi

    # Test port via curl
    echo "Test port 80 via curl..."
    PORT_TEST=$(curl -Is $LB_URL -m 5 | head -n 1)
    if echo "$PORT_TEST" | grep -q "HTTP"; then
        echo "Port 80 : ✅ Joignable"
        PORT_STATUS="OK"
    else
        echo "Port 80 : ❌ Injoignable"
        PORT_STATUS="KO"
    fi

    # Test endpoint santé (plusieurs chemins)
    HEALTH_STATUS="KO"
    for PATH in "${HEALTH_PATHS[@]}"; do
        CODE=$(curl -s -o /dev/null -w "%{http_code}" $LB_URL$PATH)
        if [ "$CODE" == "200" ]; then
            echo "Endpoint santé ($PATH) : ✅ OK"
            HEALTH_STATUS="OK"
            break
        fi
    done
    if [ "$HEALTH_STATUS" == "KO" ]; then
        echo "Endpoint santé : ❌ Aucun chemin valide trouvé (Codes testés : ${HEALTH_PATHS[*]})"
    fi

    # Résumé
    echo ""
    echo "Résumé $LB_NAME : HTTP=$HTTP_STATUS, DNS=$DNS_STATUS, PORT=$PORT_STATUS, HEALTH=$HEALTH_STATUS"
    echo ""
}

# Tester Frontend et Backend
tester_lb "Frontend LB" $FRONTEND_LB_URL
tester_lb "Backend LB" $BACKEND_LB_URL

echo "=== Fin des tests ==="
