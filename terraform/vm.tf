resource "opennebula_virtual_machine" "ubuntu" {

  template_id = var.opennebula_template_id

  name = "ubuntu-22-04"

  cpu    = 0.5
  memory = 1024
  group  = var.opennebula_group

  context = {
    START_SCRIPT   = "apt update"
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
