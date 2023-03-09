#!/bin/sh

TIPO_NODO=$(echo "$1" | cut -d "-" -f 2)
NUM_NODO=$(echo "$1" | cut -d "-" -f 3)

case $TIPO_NODO in
master) DIRECCION=$(terraform -chdir=/terraform output --json master | jq -r .connection_ip) ;;
node) DIRECCION=$(terraform -chdir=/terraform output --json nodes | jq -r .[$NUM_NODO].connection_ip) ;;
haproxy) DIRECCION=$(terraform -chdir=/terraform output --json haproxy | jq -r .connection_ip) ;;
esac

printf "\n"

ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -g -L '*:9999:127.0.0.1:32000' -N -f -l root "$DIRECCION"

read -n 1 -s -r -p "Pulsa cualquier tecla para desconectar... "

printf "\n\n"

echo "Tunel desconectado."
