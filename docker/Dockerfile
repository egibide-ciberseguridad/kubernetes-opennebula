ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION}

# Definir el directorio actual
WORKDIR /root

# Instalar los paquetes necesarios
RUN apk add terraform ansible openssh curl

# Copiar el script para crear la clave SSH
COPY generar_clave.sh /usr/local/bin/generar_clave.sh
RUN chmod +x /usr/local/bin/generar_clave.sh

# Instalar kubectl
COPY arquitectura.sh /usr/local/bin/arquitectura.sh
RUN chmod +x /usr/local/bin/arquitectura.sh

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(arquitectura.sh)/kubectl" \
    && mv kubectl /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl \
