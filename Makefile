#!make

ifneq (,$(wildcard ./.env))
    include .env
    export
else
$(error No se encuentra el fichero .env)
endif

help: _header
	${info}
	@echo Opciones:
	@echo -----------------------------------------------------
	@echo build
	@echo init / plan / apply / show / output / destroy
	@echo taint resource=[resource_name] / taint-all
	@echo urls
	@echo -----------------------------------------------------
	@echo workspace
	@echo ssh [node=kube-node-0]
	@echo -----------------------------------------------------
	@echo dashboard-token / rook-dashboard-password
	@echo grafana-password / headlamp-token
	@echo -----------------------------------------------------
	@echo kubenode-status / calico-bird-status / rook-status
	@echo -----------------------------------------------------
	@echo rm-node remove=[node_name] / rm-rook osd=[999]
	@echo -----------------------------------------------------
	@echo clean / clean-tfstate
	@echo nuke-apply
	@echo -----------------------------------------------------

_header:
	@echo ----------
	@echo Kubernetes
	@echo ----------

urls: _header _urls_command

_urls_command:
	${info }
	@echo ---------------------------------------------------
	@echo [Portainer] https://kubernetes.arriaga.eu
	@echo [Headlamp] https://headlamp.arriaga.eu
	@echo [Dashboard] https://dashboard.arriaga.eu
	@echo [Vault] https://vault.arriaga.eu
	@echo [Grafana] https://grafana.arriaga.eu
	@echo [Rook] https://rook.arriaga.eu
	@echo ---------------------------------------------------

build:
	@docker compose build --pull

init:
	@touch private/hosts.txt
	@docker compose run -q --rm terraform-ansible generar_clave.sh
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform init -upgrade

plan:
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform plan

_apply_command:
	@docker compose run -q --rm terraform-ansible time -f "Tiempo total: %E" terraform -chdir=/terraform apply -auto-approve

apply: _header _apply_command _urls_command

show:
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform show

output:
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform output

destroy:
	@docker compose run -q --rm terraform-ansible time -f "Tiempo total: %E" terraform -chdir=/terraform destroy -auto-approve

resource?="resource_name"

taint:
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint $(resource)

taint-all:
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.hosts_local
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.hosts_haproxy
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.hosts_master
	@docker compose run -q --rm terraform-ansible taint_nodes.sh
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_haproxy_upgrade
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_master
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_haproxy
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_dashboard
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_headlamp
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_vault
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_portainer
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_rook
	@docker compose run -q --rm terraform-ansible terraform -chdir=/terraform taint terraform_data.ansible_extras

workspace:
	@docker compose run -q --rm terraform-ansible

node?="kube-master"

ssh:
	@docker compose run -q --rm terraform-ansible run_ssh.sh $(node)

dashboard-token:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n kubernetes-dashboard create token admin-user --duration=720h'

headlamp-token:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n kube-system create token headlamp-admin --duration=720h'

rook-dashboard-password:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o json | jq -r ".data.password|@base64d"'

grafana-password:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl get secret --namespace grafana grafana-secrets -o jsonpath="{.data.admin-password}" | base64 --decode ; echo'

kubenode-status:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl get nodes'

calico-bird-status:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'calicoctl node status'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-haproxy' 'birdc show status'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-haproxy' 'birdc show protocols'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-haproxy' 'birdc show route'

rook-status:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph status'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd status'

osd?="999"

rm-rook:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas=0'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd out osd.$(osd)'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd crush remove osd.$(osd)'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph auth del osd.$(osd)'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph delete deployment rook-ceph-osd-$(osd)'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas=1'

remove?="node_name"

rm-node:
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl drain $(remove) --delete-emptydir-data --ignore-daemonsets'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl delete node $(remove)'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd crush remove $(remove)'

clean:
	@docker compose down -v --remove-orphans

clean-tfstate:
	@docker compose run -q --rm terraform-ansible /bin/sh -c 'rm -f /terraform/terraform.tfstate*'

nuke-apply: clean build init destroy apply

versions:
	${info }
	@echo '--- Kubernetes ---'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubelet --version'
	@echo '--- Calico ---'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'calicoctl version'
	@echo '--- HAProxy ---'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-haproxy' 'haproxy -v'
	@echo '--- HAProxy Ingress Controller ---'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-haproxy' 'haproxy-ingress-controller --version'
	@echo '--- Kubernetes Dashboard ---'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'helm show chart kubernetes-dashboard/kubernetes-dashboard | grep ^version'
	@echo '--- Rook ---'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'kubectl describe pod -n rook-ceph -l app=rook-ceph-operator | grep Image:'
	@echo '--- Portainer ---'
	@docker compose run -q --rm terraform-ansible run_on.sh 'kube-master' 'helm show chart portainer/portainer | grep ^appVersion'
