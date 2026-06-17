#!/bin/sh
# Reboot all nodes sequentially, waiting for each to come back before rebooting the next.

NODES=$(terraform -chdir=/terraform output --json nodes | jq -r '.[].name')

for NODE in $NODES; do
    echo ">>> Rebooting $NODE ..."

    # Trigger reboot via run_on.sh (handles bastion routing)
    run_on.sh "$NODE" 'reboot'

    # Wait until the node responds to SSH (up to 5 minutes = 30 polls)
    for i in $(seq 1 30); do
        if run_on.sh "$NODE" 'echo ok' >/dev/null 2>&1; then
            echo ">>> $NODE is back online."
            break
        fi
        echo "    Waiting for $NODE to come back... ($i/30)"
        sleep 10
    done

    if [ "$i" = "30" ]; then
        echo "ERROR: $NODE did not come back within 5 minutes."
        exit 1
    fi
done
