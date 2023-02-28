# kubernetes-opennebula

Cluster [Kubernetes](https://kubernetes.io) desplegado con [Terraform](https://www.terraform.io)
y [Ansible](https://www.ansible.com) en [OpenNebula](https://opennebula.io).

## Puesta en marcha

1. Crear el fichero `.env` a partir de `env-example` y configurar las variables.
2. Crear el fichero `terraform/variables.tf` a partir de `terraform/variables.tf.example` y configurar las variables.
3. Construir el contenedor donde se ejecuta Terraform.

    ```shell
    make build
    ```
4. Crear la clave privada SSH para Ansible e inicializar Terraform.

    ```shell
    make init
    ```

5. Desplegar el cluster en OpenNebula.

    ```shell
    make apply
    ```

6. Conectarse al nodo maestro del cluster.

    ```shell
    make ssh
    ```

## Acceso al Dashboard

Obtener el token temporal de acceso:

```shell
make token
```

Acceder al Dashboard con la IP de cualquiera de los nodos del cluster, en el puerto 32000 y por HTTPS. Por ejemplo:

https://172.20.227.242:32000

### Redirección mediante la IP pública

Si solo tenemos acceso al cluster mediante la IP pública del master, podemos crear un túnel SSH al puerto del Dashboard
haciendo:

```
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 9999:127.0.0.1:32000 -N -f -l root $(docker compose run --rm terraform-ansible terraform -chdir=/terraform output -raw master_connection_ip)
```

Y acceder a:

https://localhost:9999

## Timeline de creación del cluster

![](docs/orden_creacion_kubernetes.png)

## Referencias

- [Documentación del proveedor de OpenNebula](https://registry.terraform.io/providers/OpenNebula/opennebula/latest/docs)
- [Cluster de Kubernetes con Vagrant](https://github.com/ijaureguialzo/vagrant-kubernetes)
- [Install and Set Up kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [alpine-kubectl](https://github.com/wayarmy/alpine-kubectl/blob/master/1.8.0/Dockerfile)
- [How to detect 386, amd64, arm, or arm64 OS architecture via shell/bash](https://stackoverflow.com/questions/48678152/how-to-detect-386-amd64-arm-or-arm64-os-architecture-via-shell-bash)
- [print terraform output from list of list to a list of strings](https://stackoverflow.com/questions/71748316/print-terraform-output-from-list-of-list-to-a-list-of-strings)
- [How to Install Kubernetes on Ubuntu 22.04 / Ubuntu 20.04](https://www.itzgeek.com/how-tos/linux/ubuntu-how-tos/install-kubernetes-on-ubuntu-22-04.html)
- [How to Install Kubernetes Cluster on Ubuntu 22.04](https://www.linuxtechi.com/install-kubernetes-on-ubuntu-22-04/)
- [Ubuntu 22.04 and Kubernetes recently Broke Compatibility with Each Other (and how to work around it)](https://www.learnlinux.tv/ubuntu-22-04-and-kubernetes-recently-broke-compatibility-with-each-other-and-how-to-work-around-it/)
- [Ansible playbook to upgrade Ubuntu/Debian servers and reboot if needed](https://www.jeffgeerling.com/blog/2022/ansible-playbook-upgrade-ubuntudebian-servers-and-reboot-if-needed)
- [Ansible Register](https://www.educba.com/ansible-register/)
- [How to Use Environment Variables on Terraform](https://medium.com/codex/how-to-use-environment-variables-on-terraform-f2ab6f95f82d)
- [How can I manage keyring files in trusted.gpg.d with ansible playbook since apt-key is deprecated?](https://stackoverflow.com/a/73805885)

### HAProxy

- [Install Calico with Kubernetes API datastore, 50 nodes or less](https://docs.tigera.io/calico/3.25/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico-with-kubernetes-api-datastore-50-nodes-or-less)
- [Run the HAProxy Kubernetes Ingress Controller Outside of Your Kubernetes Cluster](https://www.haproxy.com/blog/run-the-haproxy-kubernetes-ingress-controller-outside-of-your-kubernetes-cluster/)
- [Enable external mode for an on-premises Kubernetes installation](https://www.haproxy.com/documentation/kubernetes/latest/installation/community/external-mode/external-mode-on-premises/)
- [Install calicoctl](https://docs.tigera.io/calico/3.25/operations/calicoctl/install)
- [Route traffic to an example app](https://www.haproxy.com/documentation/kubernetes/latest/usage/ingress/)
- [ingress-controller-external-example](https://github.com/haproxytechblog/ingress-controller-external-example/blob/master/app.yaml)
- [The Ultimate Guide To Using Calico, Flannel, Weave and Cilium](https://platform9.com/blog/the-ultimate-guide-to-using-calico-flannel-weave-and-cilium/)

### Rook

- [Rook](https://rook.io)
- [Getting Started](https://rook.io/docs/rook/v1.10/Getting-Started/intro/)
- [Quickstart](https://rook.io/docs/rook/v1.10/Getting-Started/quickstart/)
- [Host Storage Cluster](https://rook.io/docs/rook/v1.10/CRDs/Cluster/host-cluster/)
- [Troubleshooting](https://rook.io/docs/rook/v1.10/Troubleshooting/ceph-toolbox/)
- [Block Storage (RBD)](https://rook.io/docs/rook/v1.10/Storage-Configuration/Block-Storage-RBD/block-storage/)
- [Shared Filesystem (CephFS)](https://rook.io/docs/rook/v1.10/Storage-Configuration/Shared-Filesystem-CephFS/filesystem-storage/)
