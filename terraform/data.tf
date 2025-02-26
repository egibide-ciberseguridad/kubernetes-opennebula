data "opennebula_templates" "busqueda" {
  name_regex = local.opennebula.vm.name
  sort_on    = "register_date"
  order      = "ASC" # La más reciente
}

data "opennebula_template" "template" {
  id = data.opennebula_templates.busqueda.templates[0].id
}

data "opennebula_virtual_network" "network" {
  name = local.opennebula.vm.network
}

data "opennebula_image" "empty_image" {
  name = "Empty disk"
}
