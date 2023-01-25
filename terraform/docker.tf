// Instalar y configurar Docker mediante Ansible

locals {
  ips = join(",", [
    opennebula_virtual_machine.ubuntu.nic[0].computed_ip,
    lookup(var.ip_publica, opennebula_virtual_machine.ubuntu.nic[0].computed_ip, "")
  ])
}

resource "null_resource" "docker" {
  depends_on = [
    opennebula_virtual_machine.ubuntu
  ]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook -i "${local.ips}" /ansible/playbook.yml --extra-vars "UBUNTU_RELEASE=${var.ubuntu_release}"
    EOT
  }
}
