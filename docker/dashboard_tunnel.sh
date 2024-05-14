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

ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@$HAPROXY_IP" \
    -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -g -L '*:9999:127.0.0.1:32000' -N -f -l root "$DIRECCION"

read -n 1 -s -r -p "Pulsa cualquier tecla para desconectar... "

printf "\n\n"

echo "Tunel desconectado."
