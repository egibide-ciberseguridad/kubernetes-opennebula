#!/bin/sh

TIPO_NODO=$(echo "$1" | cut -d "-" -f 2)
NUM_NODO=$(echo "$1" | cut -d "-" -f 3)

case $TIPO_NODO in
master) DIRECCION=$(terraform -chdir=/terraform output --json master | jq -r .connection_ip) ;;
node) DIRECCION=$(terraform -chdir=/terraform output --json nodes | jq -r .[$NUM_NODO].connection_ip) ;;
haproxy) DIRECCION=$(terraform -chdir=/terraform output --json haproxy | jq -r .connection_ip) ;;
esac

ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@$DIRECCION" "$2" && echo ""
