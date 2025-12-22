resource "terraform_data" "ansible_dashboard" {
  depends_on = [
    terraform_data.ansible_nodes_kubernetes
  ]

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.master.name}," \
        --ssh-common-args '${local.ssh_proxy}' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        /ansible/dashboard-playbook.yml
    EOT
  }
}
