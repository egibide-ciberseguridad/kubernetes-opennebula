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
	@echo ------------------------------------------
	@echo build
	@echo init / apply / show / output / destroy
	@echo workspace
	@echo ssh / ssh-keyscan
	@echo clean
	@echo ------------------------------------------

_header:
	@echo ----------
	@echo Kubernetes
	@echo ----------

build:
	@docker compose build

init:
	@docker compose run --rm terraform-ansible generar_clave.sh
	@docker compose run --rm terraform-ansible terraform -chdir=/terraform init

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

ssh:
	@docker compose run --rm terraform-ansible /bin/sh -c "$(shell docker compose run --rm terraform-ansible terraform -chdir=/terraform output --raw ssh-command)"

ssh-keyscan:
	@docker compose run --rm terraform-ansible /bin/sh -c "$(shell docker compose run --rm terraform-ansible terraform -chdir=/terraform output --raw ssh-keyscan)"

clean:
	@docker compose down -v --remove-orphans
