resource "opennebula_virtual_network" "public" {
  name   = "kubernetes-public"
  type   = "bridge"
  bridge = "aulas"
  mtu    = 1500

  gateway      = "172.20.1.2"
  dns          = "192.168.10.1 1.1.1.1"
  network_mask = "255.255.0.0"

  security_groups = [0]
}

resource "opennebula_virtual_network_address_range" "public" {
  virtual_network_id = opennebula_virtual_network.public.id
  ar_type            = "IP4"
  size               = local.opennebula.networks.public.network_size
  ip4                = local.opennebula.networks.public.network_ip
}

resource "opennebula_virtual_network" "cluster" {
  name   = "kubernetes-cluster"
  type   = "bridge"
  bridge = "aulas"
  mtu    = 1500

  gateway      = "172.20.1.2"
  dns          = "192.168.10.1 1.1.1.1"
  network_mask = "255.255.0.0"

  security_groups = [0]
}

resource "opennebula_virtual_network_address_range" "cluster" {
  virtual_network_id = opennebula_virtual_network.cluster.id
  ar_type            = "IP4"
  size               = local.opennebula.networks.cluster.network_size
  ip4                = local.opennebula.networks.cluster.network_ip
}
