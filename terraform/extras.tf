resource "null_resource" "ansible_extras" {
  depends_on = [
    null_resource.ansible_rook
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
        /ansible/extras-playbook.yml
    EOT
  }
}
