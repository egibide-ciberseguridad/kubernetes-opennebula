#!/bin/bash
# Reboot all nodes sequentially, waiting for each to come back before rebooting the next.

MAX_RETRIES=30
POLL_INTERVAL=10

wait_for_node() {
    local NODE="$1"
    for i in $(seq 1 $MAX_RETRIES); do
        if run_on.sh "$NODE" 'echo ok' >/dev/null 2>&1; then
            echo ">>> $NODE is back online."
            return 0
        fi
        echo "    Waiting for $NODE to come back... ($i/$MAX_RETRIES)"
        sleep $POLL_INTERVAL
    done
    echo "ERROR: $NODE did not come back within $((MAX_RETRIES * POLL_INTERVAL)) seconds."
    exit 1
}

NODES=$(terraform -chdir=/terraform output --json nodes | jq -r '.[].name')

for NODE in $NODES; do
    echo ">>> Rebooting $NODE ..."
    run_on.sh "$NODE" 'reboot'
    wait_for_node "$NODE"
done

for NODE in kube-master kube-haproxy; do
    echo ">>> Rebooting $NODE ..."
    run_on.sh "$NODE" 'reboot'
    wait_for_node "$NODE"
done
