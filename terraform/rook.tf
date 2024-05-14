resource "null_resource" "ansible_rook" {
  depends_on = [
    null_resource.ansible_nodes_kubernetes
  ]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.master.name}," \
        --ssh-common-args '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}"' \
        --extra-vars "haproxy_connection_ip=${local.haproxy.connection_ip}" \
        /ansible/rook-playbook.yml
    EOT
  }
}
