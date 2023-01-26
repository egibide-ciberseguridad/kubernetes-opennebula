resource "opennebula_virtual_machine" "nodes" {

  depends_on = [
    opennebula_virtual_machine.master
  ]

  count = var.num_nodos

  template_id = var.opennebula_template_id

  name = "kube-node-${count.index}"

  cpu    = 0.5
  vcpu   = 2
  memory = 1024
  group  = var.opennebula_group

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = file("~/.ssh/id_rsa.pub")
  }

  nic {
    model      = "virtio"
    network_id = var.opennebula_network_id
  }

  disk {
    image_id = var.opennebula_image_id
    target   = "vda"
    size     = 8192
  }
}

resource "null_resource" "ansible_nodes" {
  depends_on = [
    null_resource.ansible_master
  ]

  count = var.num_nodos

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
        --extra-vars "UBUNTU_RELEASE=${var.ubuntu_release} node_ip=${local.nodes[count.index].private_ip}"
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
      connection_ip = var.ansible_connect_to_public_ip ? lookup(var.ip_publica, node.nic[0].computed_ip, "") : node.nic[0].computed_ip
    }
  ]
}

output "nodes" {
  value = local.nodes
}
