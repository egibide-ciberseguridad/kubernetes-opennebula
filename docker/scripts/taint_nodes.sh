#!/bin/bash

NUM_NODOS=$(echo var.nodes | terraform -chdir=/terraform console)

for((i = 0; i < NUM_NODOS; i++))
do
    terraform -chdir=/terraform taint terraform_data.hosts_nodes[$i]
    terraform -chdir=/terraform taint terraform_data.ansible_nodes_common[$i]
    terraform -chdir=/terraform taint terraform_data.ansible_nodes_kubernetes[$i]
done
