resource "opennebula_virtual_machine" "master" {

  template_id = var.opennebula_template_id

  name = "kube-master"

  cpu    = 1
  vcpu   = 2
  memory = 2048
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

resource "null_resource" "ansible_master" {
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

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook \
        -i "${local.master.connection_ip}," \
        /ansible/master-playbook.yml \
        --extra-vars "UBUNTU_RELEASE=${var.ubuntu_release} node_ip=${local.master.private_ip}"
    EOT
  }
}

locals {
  master = {
    private_ip    = opennebula_virtual_machine.master.nic[0].computed_ip
    public_ip     = lookup(var.ip_publica, opennebula_virtual_machine.master.nic[0].computed_ip, "")
    connection_ip = var.ansible_connect_to_public_ip ? lookup(var.ip_publica, opennebula_virtual_machine.master.nic[0].computed_ip, "") : opennebula_virtual_machine.master.nic[0].computed_ip
  }
}

output "master" {
  value = local.master
}
