ARG TERRAFORM_VERSION

FROM hashicorp/terraform:${TERRAFORM_VERSION}

# Instalar los paquetes necesarios
RUN apk add ansible openssh curl jq

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(arquitectura.sh)/kubectl" \
    && mv kubectl /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl

# Copiar los scripts al contenedor
COPY --chmod=0755 *.sh /usr/bin/

# Definir el directorio actual
WORKDIR /root

# Mostrar el usuario y el host en el prompt
ENV PS1='\u@\h:\w\$\040'

# Eliminar la llamada a Terraform de la imagen original
ENTRYPOINT []
