data "opennebula_template" "template" {
  tags = {
    TAG = local.opennebula.vm.tag
  }
}

data "opennebula_virtual_network" "network" {
  name = local.opennebula.vm.network
}

resource "opennebula_virtual_machine" "master" {

  template_id = data.opennebula_template.template.id

  name = "kube-master"

  cpu    = local.opennebula.limits.master.cpu
  vcpu   = local.opennebula.limits.master.vcpu
  memory = local.opennebula.limits.master.memory

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = join("\n", [var.SSH_PUBLIC_KEY, file("~/.ssh/id_rsa.pub")])
  }

  group = local.opennebula.connection.group

  nic {
    model      = "virtio"
    network_id = data.opennebula_virtual_network.network.id
  }

  disk {
    image_id = data.opennebula_template.template.disk[0].image_id
    target   = "vda"
    size     = local.opennebula.limits.master.disk
  }
}

resource "null_resource" "hosts_master" {
  depends_on = [
    opennebula_virtual_machine.master
  ]

  provisioner "file" {
    connection {
      host        = local.master.connection_ip
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }
}

resource "null_resource" "ansible_master" {
  depends_on = [
    null_resource.hosts_master
  ]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.master.connection_ip}," \
        /ansible/common-playbook.yml \
        --extra-vars "node_ip=${local.master.private_ip}"
    EOT
  }

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.master.connection_ip}," \
        /ansible/master-playbook.yml \
        --extra-vars "node_ip=${local.master.private_ip}" \
        --extra-vars "haproxy_ip=${local.haproxy.private_ip}"
    EOT
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p /root/.kube
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${local.master.connection_ip}:/root/.kube/config /root/.kube/config
    EOT
  }
}

locals {
  master = {
    name          = opennebula_virtual_machine.master.name
    private_ip    = opennebula_virtual_machine.master.nic[0].computed_ip
    public_ip     = lookup(local.ip_publica, opennebula_virtual_machine.master.nic[0].computed_ip, "")
    connection_ip = local.ansible.connect_to_public_ip ? lookup(local.ip_publica, opennebula_virtual_machine.master.nic[0].computed_ip, "") : opennebula_virtual_machine.master.nic[0].computed_ip
  }
}

output "master" {
  value = local.master
}
