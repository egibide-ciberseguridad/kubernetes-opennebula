resource "opennebula_virtual_machine" "nodes" {

  depends_on = [
    opennebula_virtual_machine.master
  ]

  count = var.num_nodos

  template_id = var.opennebula_template_id

  name = "node-${count.index}"

  cpu    = 0.5
  memory = 1024
  group  = var.opennebula_group

  context = {
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
    opennebula_virtual_machine.nodes
  ]

  count = var.num_nodos

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook -i "${opennebula_virtual_machine.nodes[count.index].nic[0].computed_ip}," /ansible/playbook.yml --extra-vars "UBUNTU_RELEASE=${var.ubuntu_release}"
    EOT
  }
}

output "nodes_ips" {
  value = opennebula_virtual_machine.nodes[*].nic[0].computed_ip
}
