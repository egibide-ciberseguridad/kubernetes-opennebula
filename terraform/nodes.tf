data "opennebula_image" "empty_image" {
  name = "Empty disk"
}

resource "opennebula_virtual_machine" "nodes" {

  depends_on = [
    opennebula_virtual_machine.master
  ]

  count = var.nodes

  template_id = data.opennebula_template.template.id

  name = "kube-node-${count.index}"

  cpu    = local.opennebula.limits.nodes.cpu
  vcpu   = local.opennebula.limits.nodes.vcpu
  memory = local.opennebula.limits.nodes.memory

  lock = local.opennebula.vm.locked ? "USE" : "UNLOCK"

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = join("\n", [
      join("\n", split("|", replace(var.SSH_PUBLIC_KEY, "/[\"']/", ""))),
      file("~/.ssh/id_rsa.pub")
    ])
  }

  group = local.opennebula.connection.group

  nic {
    model      = "virtio"
    network_id = data.opennebula_virtual_network.network.id
  }

  disk {
    image_id = data.opennebula_template.template.disk[0].image_id
    target   = "vda"
    size     = local.opennebula.limits.nodes.disk1
  }

  disk {
    image_id = data.opennebula_image.empty_image.id
    target   = "vdb"
    size     = local.opennebula.limits.nodes.disk2
  }
}

resource "null_resource" "hosts_nodes" {
  depends_on = [
    opennebula_virtual_machine.nodes
  ]

  count = var.nodes

  provisioner "file" {
    connection {
      host         = local.nodes[count.index].name
      user         = "root"
      private_key  = file("~/.ssh/id_rsa")
      bastion_host = local.haproxy.connection_ip
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }
}

resource "null_resource" "ansible_nodes_common" {
  depends_on = [
    null_resource.hosts_nodes
  ]

  count = var.nodes

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.nodes[count.index].name}," \
        --ssh-common-args '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}"' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        --extra-vars "node_ip=${local.nodes[count.index].private_ip}" \
        /ansible/common-playbook.yml
    EOT
  }
}

resource "null_resource" "ansible_nodes_kubernetes" {
  depends_on = [
    null_resource.ansible_master,
    null_resource.ansible_nodes_common,
  ]

  count = var.nodes

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.nodes[count.index].name}," \
        --ssh-common-args '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}"' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        /ansible/node-playbook.yml
    EOT
  }
}

locals {
  nodes = [
    for node in opennebula_virtual_machine.nodes[*] :
    {
      name          = node.name
      private_ip    = node.nic[0].computed_ip
      public_ip     = lookup(local.ip_publica, node.nic[0].computed_ip, "")
      connection_ip = (local.ansible.connect_to_public_ip ?
        lookup(local.ip_publica, node.nic[0].computed_ip, "") :
        node.nic[0].computed_ip)
    }
  ]
}

output "nodes" {
  value = local.nodes
}
