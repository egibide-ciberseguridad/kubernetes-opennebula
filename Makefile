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
	@echo taint
	@echo -----------------------------------------------------
	@echo workspace
	@echo ssh [node=kube-node-0]
	@echo -----------------------------------------------------
	@echo dashboard-token
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

taint:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_master
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform taint null_resource.ansible_haproxy

workspace:
	@docker compose run --rm terraform-ansible /bin/sh

node?="kube-master"

ssh:
	@docker compose run --rm terraform-ansible run_ssh.sh $(node)

dashboard-token:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n kubernetes-dashboard create token admin-user --duration=720h'

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

clean:
	@docker compose down -v --remove-orphans

clean-tfstate:
	@docker compose run --rm terraform-ansible /bin/sh -c 'rm -f /terraform/terraform.tfstate*'

nuke-apply: clean build init destroy apply
