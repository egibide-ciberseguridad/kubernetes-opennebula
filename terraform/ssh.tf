output "ssh-command" {
  value     = "ssh root@${local.master.connection_ip}"
  sensitive = true
}

output "ssh-keyscan" {
  value     = "ssh-keyscan ${local.master.connection_ip} ${join(" ", local.nodes.*.connection_ip)} >~/.ssh/known_hosts 2>/dev/null"
  sensitive = true
}
