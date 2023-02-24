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
	@echo ---------------------------------------------
	@echo build
	@echo init / plan / apply / show / output / destroy
	@echo update-hosts / workspace
	@echo ssh / ssh-ha / ssh-keyscan
	@echo token
	@echo clean
	@echo nuke-apply
	@echo ---------------------------------------------

_header:
	@echo ----------
	@echo Kubernetes
	@echo ----------

build:
	@docker compose build

init:
	@docker compose run --rm terraform-ansible generar_clave.sh
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform init

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

update-hosts:
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform apply -auto-approve -replace=null_resource.hosts_master -replace=null_resource.hosts_nodes[0] -replace=null_resource.hosts_nodes[1] -replace=null_resource.hosts_nodes[2] -replace=null_resource.hosts_nodes[3] -replace=null_resource.hosts_nodes[4]

workspace:
	@docker compose run --rm terraform-ansible /bin/sh

ssh:
	@docker compose run --rm terraform-ansible run_output.sh ssh-command

ssh-ha:
	@docker compose run --rm terraform-ansible run_output.sh ssh-command-ha

ssh-keyscan:
	@docker compose run --rm terraform-ansible run_output.sh ssh-keyscan

token:
	@docker compose run --rm terraform-ansible run_on_master.sh 'kubectl -n kubernetes-dashboard create token admin-user'

clean:
	@docker compose down -v --remove-orphans

nuke-apply: clean build init destroy apply
