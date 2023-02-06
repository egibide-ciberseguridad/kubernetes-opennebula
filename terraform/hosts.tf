locals {
  hosts = join("\n", [
    "127.0.0.1 localhost localhost.localdomain",
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
