terraform {
  required_providers {
    opennebula = {
      source  = "OpenNebula/opennebula"
      version = "~> 1.4"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "opennebula" {
  endpoint = local.opennebula.connection.endpoint
  username = local.opennebula.connection.username
  password = local.opennebula.connection.token
  insecure = true
}

provider "cloudflare" {
  api_token = local.cloudflare.token
}
