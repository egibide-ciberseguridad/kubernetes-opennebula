ARG TERRAFORM_VERSION=latest

FROM hashicorp/terraform:${TERRAFORM_VERSION}

# Instalar los paquetes necesarios
RUN apk add ansible openssh curl jq make nano

RUN apk add bash bash-completion shadow && \
    chsh root --shell /bin/bash && \
    apk del shadow

# Copiar los scripts al contenedor
COPY --chmod=0755 ../scripts/*.sh /usr/bin/

# Definir el directorio actual
WORKDIR /root

# Mostrar el usuario y el host en el prompt
ENV PS1='\u@\h:\w\$\040'

# Variables de entorno de Ansible
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_PYTHON_INTERPRETER=auto_silent

# Comprobar en qué red estamos antes de hacer nada
ENTRYPOINT ["/usr/bin/comprobar_red.sh"]

CMD ["/bin/bash"]
