locals {
  hosts = join("\n", [
    "127.0.0.1 localhost localhost.localdomain",
    "172.20.227.241 ubuntu.ciber-egibide.eu",
    join( " ", [local.master.private_ip, opennebula_virtual_machine.master.name]),
    join("\n", flatten([
      for i in opennebula_virtual_machine.nodes[*] : join(" ", [i.nic[0].computed_ip, i.name])
    ])),
    ""
  ])
}

output "hosts" {
  value = local.hosts
}
