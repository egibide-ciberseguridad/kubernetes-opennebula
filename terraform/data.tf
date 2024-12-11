data "opennebula_template" "template" {
  tags = {
    TAG = local.opennebula.vm.tag
  }
}

data "opennebula_virtual_network" "network" {
  name = local.opennebula.vm.network
}

data "opennebula_image" "empty_image" {
  name = "Empty disk"
}
