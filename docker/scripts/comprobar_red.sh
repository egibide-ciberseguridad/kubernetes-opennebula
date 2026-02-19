#!/bin/sh

if ping -c 1 -W 1 "$NETWORK_TEST_IP" >/dev/null 2>&1; then
    export TF_VAR_USE_PUBLIC_IP=false
else
    export TF_VAR_USE_PUBLIC_IP=true
fi

exec "$@"
