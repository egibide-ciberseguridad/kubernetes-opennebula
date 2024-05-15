locals {
  hosts = join("\n", [
    "127.0.0.1 localhost localhost.localdomain",
    join(" ", [local.master.private_ip, opennebula_virtual_machine.master.name]),
    join("\n", flatten([
      for i in opennebula_virtual_machine.nodes[*] : join(" ", [i.nic[0].computed_ip, i.name])
    ])),
    join(" ", [local.haproxy.private_ip, opennebula_virtual_machine.haproxy.name]),
    ""
  ])
  cluster_ips = join(",", [
    local.master.private_ip,
    join(",", flatten([
      for i in opennebula_virtual_machine.nodes[*] : i.nic[0].computed_ip
    ])),
  ])
}

output "hosts" {
  value = local.hosts
}

output "cluster_ips" {
  value = local.cluster_ips
}
