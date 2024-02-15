resource "null_resource" "ansible_rook" {
  depends_on = [
    null_resource.ansible_nodes_kubernetes
  ]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.master.connection_ip}," \
        /ansible/rook-playbook.yml
    EOT
  }
}
