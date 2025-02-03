ARG TERRAFORM_VERSION=latest

FROM hashicorp/terraform:${TERRAFORM_VERSION}

# Instalar los paquetes necesarios
RUN apk add ansible openssh curl jq

RUN apk add bash bash-completion shadow && \
    chsh root --shell /bin/bash && \
    apk del shadow

# Copiar los scripts al contenedor
COPY --chmod=0755 *.sh /usr/bin/

# Definir el directorio actual
WORKDIR /root

# Mostrar el usuario y el host en el prompt
ENV PS1='\u@\h:\w\$\040'

# Eliminar la llamada a Terraform de la imagen original
ENTRYPOINT []

CMD ["/bin/bash"]
