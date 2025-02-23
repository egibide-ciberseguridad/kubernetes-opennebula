#!/bin/sh

mkdir -p ~/.ssh && chmod 0700 ~/.ssh

cd ~/.ssh || exit

if [ ! -f id_rsa ]; then
    ssh-keygen -b 2048 -t rsa -f id_rsa -q -N ""
    chmod 400 id_rsa
    echo
    echo "Nueva clave privada generada."
fi

echo
echo "Clave pública generada:"
echo

cat id_rsa.pub
