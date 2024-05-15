#!/bin/sh

TIPO_NODO=$(echo "$1" | cut -d "-" -f 2)
NUM_NODO=$(echo "$1" | cut -d "-" -f 3)

HAPROXY_IP=$(terraform -chdir=/terraform output --json haproxy | jq -r .connection_ip)

case $TIPO_NODO in
master) DIRECCION=$(terraform -chdir=/terraform output --json master | jq -r .name) ;;
node) DIRECCION=$(terraform -chdir=/terraform output --json nodes | jq -r .[$NUM_NODO].name) ;;
haproxy) DIRECCION=$(terraform -chdir=/terraform output --json haproxy | jq -r .name) ;;
esac

printf "\n"

COMANDO='kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 > /dev/null 2>&1'
ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@$HAPROXY_IP" \
-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@$DIRECCION" "$COMANDO" &

ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@$HAPROXY_IP" \
    -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -g -L '*:9999:127.0.0.1:8443' -N -f -l root "$DIRECCION" &

printf "Pulsa cualquier tecla para desconectar... "
read -n 1 -s -r

COMANDO='pkill -f "port-forward"'
ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@$HAPROXY_IP" \
-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@$DIRECCION" "$COMANDO" && echo ""

printf "\nTunel desconectado.\n"
