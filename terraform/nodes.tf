resource "opennebula_virtual_machine" "nodes" {

  depends_on = [
    opennebula_virtual_machine.master
  ]

  count = local.kubernetes.nodes

  template_id = data.opennebula_template.template.id

  name = "kube-node-${count.index}"

  cpu    = 0.5
  vcpu   = 2
  memory = 1024

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = file("~/.ssh/id_rsa.pub")
  }

  nic {
    model      = "virtio"
    network_id = data.opennebula_virtual_network.network.id
  }

  disk {
    image_id = data.opennebula_template.template.disk[0].image_id
    target   = "vda"
    size     = 8192
  }
}

resource "null_resource" "ansible_nodes" {
  depends_on = [
    null_resource.ansible_master
  ]

  count = local.kubernetes.nodes

  provisioner "file" {
    connection {
      host        = local.nodes[count.index].connection_ip
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook \
        -i "${local.nodes[count.index].connection_ip}," \
        /ansible/node-playbook.yml \
        --extra-vars "node_ip=${local.master.private_ip}"
    EOT
  }
}

locals {
  nodes = [
    for node in opennebula_virtual_machine.nodes[*] :
    {
      name          = node.name
      private_ip    = node.nic[0].computed_ip
      public_ip     = lookup(var.ip_publica, node.nic[0].computed_ip, "")
      connection_ip = local.ansible.connect_to_public_ip ? lookup(var.ip_publica, node.nic[0].computed_ip, "") : node.nic[0].computed_ip
    }
  ]
}

output "nodes" {
  value = local.nodes
}
