ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION}

# Instalar los paquetes necesarios
RUN apk add terraform ansible openssh curl

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(arquitectura.sh)/kubectl" \
    && mv kubectl /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl

# Copiar los scripts al contenedor
COPY --chmod=0755 *.sh /usr/bin/

# Definir el directorio actual
WORKDIR /root
