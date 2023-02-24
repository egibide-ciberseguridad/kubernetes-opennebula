resource "null_resource" "ansible_dashboard" {
  depends_on = [
    null_resource.ansible_nodes_kubernetes
  ]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook \
        -i "${local.master.connection_ip}," \
        /ansible/dashboard-playbook.yml
    EOT
  }
}
