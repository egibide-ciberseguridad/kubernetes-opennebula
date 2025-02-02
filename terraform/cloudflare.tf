resource "cloudflare_record" "domain_name" {
  allow_overwrite = true
  zone_id         = local.cloudflare.zone_id
  name            = local.cloudflare.subdomain
  content         = local.haproxy.public_ip
  type            = "A"
  proxied         = true
}

locals {
  flat_cnames = flatten([
    for cname in local.cloudflare.cnames : {
      name  = "${local.cloudflare.subdomain}.${local.cloudflare.domain}-${cname}"
      cname = cname
    }
  ])
}

resource "cloudflare_record" "cname" {
  for_each = {
    for name, cname in local.flat_cnames : cname.name => cname
  }
  allow_overwrite = true
  zone_id = local.cloudflare.zone_id
  name    = each.value.cname
  content = "${local.cloudflare.subdomain}.${local.cloudflare.domain}"
  type    = "CNAME"
  proxied = true
}
