terraform {
  required_providers {
    opennebula = {
      source  = "OpenNebula/opennebula"
      version = "~> 1.4"
    }
  }
}

provider "opennebula" {
  endpoint = "https://opennebula.egibide.org/RPC2"
  username = local.opennebula.connection.username
  password = local.opennebula.connection.token
  insecure = true
}
