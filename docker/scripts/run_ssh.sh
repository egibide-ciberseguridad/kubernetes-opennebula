#!/bin/sh

TIPO_NODO=$(echo "$1" | cut -d "-" -f 2)
NUM_NODO=$(echo "$1" | cut -d "-" -f 3)

HAPROXY_IP=$(terraform -chdir=/terraform output --json haproxy | jq -r .connection_ip)
SSH_PROXY=$(echo local.ansible.connect_to_public_ip | terraform -chdir=/terraform console)

case $TIPO_NODO in
master) DIRECCION=$(terraform -chdir=/terraform output --json master | jq -r .name) ;;
node) DIRECCION=$(terraform -chdir=/terraform output --json nodes | jq -r .[$NUM_NODO].name) ;;
haproxy) DIRECCION=$(terraform -chdir=/terraform output --json haproxy | jq -r .name) ;;
esac

if [ "$SSH_PROXY" = "true" ]; then
    ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@$HAPROXY_IP" \
        -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@$DIRECCION"
else
    ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@$DIRECCION"
fi
