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
	@echo -----------------------------------------------------
	@echo workspace
	@echo ssh [node=kube-node-0]
	@echo -----------------------------------------------------
	@echo dashboard-token / dashboard-tunnel [node=kube-node-0]
	@echo -----------------------------------------------------
	@echo kubenode-status / calico-bird-status / rook-status
	@echo -----------------------------------------------------
	@echo clean / clean-tfstate
	@echo nuke-apply
	@echo -----------------------------------------------------

_header:
	@echo ----------
	@echo Kubernetes
	@echo ----------

build:
	@docker compose build

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

workspace:
	@docker compose run --rm terraform-ansible /bin/sh

node?="kube-master"

ssh:
	@docker compose run --rm terraform-ansible run_ssh.sh $(node)

dashboard-token:
	@docker compose run --rm terraform-ansible run_on.sh 'kube-master' 'kubectl -n kubernetes-dashboard create token admin-user --duration=48h'

dashboard-tunnel:
	${info }
	@echo ----------------------------------
	@echo [Dashboard] https://localhost:9999
	@echo ----------------------------------
	@docker compose run --rm -p 9999:9999 terraform-ansible dashboard_tunnel.sh $(node)

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

clean:
	@docker compose down -v --remove-orphans

clean-tfstate:
	@docker compose run --rm terraform-ansible /bin/sh -c 'rm -f /terraform/terraform.tfstate*'

nuke-apply: clean build init destroy apply
