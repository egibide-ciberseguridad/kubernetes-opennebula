#!/bin/sh

ssh root@$(terraform -chdir=/terraform output --raw master_connection_ip) "$1" && echo ""
