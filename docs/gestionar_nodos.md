# Añadir o quitar nodos al cluster

## Añadir

1. Modificar el fichero `terraform/variables.tf` y aumentar el número de nodos.

2. Actualizar la configuración con `make taint apply`.

## Quitar

1. Quitar el nodo del cluster con `make rm-node remove=nombre_nodo`.

2. Quitar el nodo de almacenamiento con `make rm-rook osd=n` donde `n` es el número que nodo que aparece en
   `make rook-status`.

3. Esperar a que la salida de `make rook-status` se estabilice.

4. Modificar el fichero `terraform/variables.tf` y reducir el número de nodos.

5. Actualizar la configuración con `make taint apply`.
