ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION}

# Instalar los paquetes necesarios
RUN apk add terraform ansible openssh curl

# Copiar el script para crear la clave SSH
COPY --chmod=0755 generar_clave.sh /usr/bin/generar_clave.sh

# Instalar kubectl
COPY --chmod=0755 arquitectura.sh /usr/bin/arquitectura.sh

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(arquitectura.sh)/kubectl" \
    && mv kubectl /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl

# Definir el directorio actual
WORKDIR /root
