#!make

ifneq (,$(wildcard ./.env))
    include .env
    export
else
$(error No se encuentra el fichero .env)
endif

help: _header
	${info }
	@echo Opciones:
	@echo -----------------------------------------------------
	@echo build
	@echo init / plan / apply / show / output / destroy
	@echo taint resource=[resource_name] / taint-all
	@echo -----------------------------------------------------
	@echo workspace
	@echo ssh [node=kube-node-0]
	@echo -----------------------------------------------------
	@echo dashboard-token / rook-dashboard-password
	@echo grafana-password
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

build:
	@docker compose build --pull

init:
	@touch private/hosts.txt
	@docker compose run --rm terraform-ansible generar_clave.sh
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform init -upgrade

plan:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform plan

apply:
	@docker compose run --rm terraform-ansible time -f "Tiempo total: %E" terraform -chdir=/terraform apply -auto-approve

show:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform show

output:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform output

destroy:
	@docker compose run --rm terraform-ansible time -f "Tiempo total: %E" terraform -chdir=/terraform destroy -auto-approve

resource?="resource_name"

taint:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint $(resource)

taint-all:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.hosts_haproxy
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.hosts_master
	@docker compose run --rm terraform-ansible taint_nodes.sh
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_haproxy_upgrade
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_master
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_haproxy
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_dashboard
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_portainer
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_rook
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_extras

workspace:
	@docker compose run --rm terraform-ansible

node?="kube-master"

ssh:
	@docker compose run --rm terraform-ansible run_ssh.sh $(node)

dashboard-token:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n kubernetes-dashboard create token admin-user --duration=720h'

rook-dashboard-password:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o json | jq -r ".data.password|@base64d"'

grafana-password:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl get secret --namespace grafana grafana-secrets -o jsonpath="{.data.admin-password}" | base64 --decode ; echo'

kubenode-status:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl get nodes'

calico-bird-status:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'calicoctl node status'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-haproxy' 'birdc show status'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-haproxy' 'birdc show protocols'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-haproxy' 'birdc show route'

rook-status:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph status'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd status'

osd?="999"

rm-rook:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas=0'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd out osd.$(osd)'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd crush remove osd.$(osd)'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph auth del osd.$(osd)'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph delete deployment rook-ceph-osd-$(osd)'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas=1'

remove?="node_name"

rm-node:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl drain $(remove) --delete-emptydir-data --ignore-daemonsets'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl delete node $(remove)'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n rook-ceph exec -i deploy/rook-ceph-tools -- ceph osd crush remove $(remove)'

clean:
	@docker compose down -v --remove-orphans

clean-tfstate:
	@docker compose run --rm terraform-ansible /bin/sh -c 'rm -f /terraform/terraform.tfstate*'

nuke-apply: clean build init destroy apply

versions:
	${info }
	@echo '--- Kubernetes ---'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubelet --version'
	@echo '--- Calico ---'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'calicoctl version'
	@echo '--- HAProxy ---'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-haproxy' 'haproxy -v'
	@echo '--- HAProxy Ingress Controller ---'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-haproxy' 'haproxy-ingress-controller --version'
	@echo '--- Kubernetes Dashboard ---'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'helm show chart kubernetes-dashboard/kubernetes-dashboard | grep ^version'
	@echo '--- Rook ---'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl describe pod -n rook-ceph -l app=rook-ceph-operator | grep Image:'
	@echo '--- Portainer ---'
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'helm show chart portainer/portainer | grep ^appVersion'
