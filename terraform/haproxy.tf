resource "opennebula_virtual_machine" "haproxy" {

  template_id = data.opennebula_template.template.id

  name = "kube-haproxy"

  cpu    = local.opennebula.limits.haproxy.cpu
  vcpu   = local.opennebula.limits.haproxy.vcpu
  memory = local.opennebula.limits.haproxy.memory

  lock = local.opennebula.vm.locked ? "USE" : "UNLOCK"

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = join("\n", [
      join("\n", split("|", replace(var.SSH_PUBLIC_KEY, "/[\"']/", ""))),
      file("~/.ssh/id_rsa.pub")
    ])
  }

  group = local.opennebula.connection.group

  nic {
    model      = "virtio"
    network_id = data.opennebula_virtual_network.network.id
  }

  disk {
    image_id = data.opennebula_template.template.disk[0].image_id
    target   = "vda"
    size     = local.opennebula.limits.haproxy.disk
  }
}

resource "null_resource" "hosts_haproxy" {
  depends_on = [
    opennebula_virtual_machine.haproxy
  ]

  provisioner "file" {
    connection {
      host        = local.haproxy.connection_ip
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
    }

    content     = local.hosts
    destination = "/etc/hosts"
  }
}

resource "null_resource" "ansible_haproxy_upgrade" {
  depends_on = [
    null_resource.hosts_haproxy,
  ]

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.haproxy.connection_ip}," \
        --extra-vars "node_ip=${local.haproxy.private_ip}" \
        --extra-vars "{ "ips" : [${local.cluster_ips}]}" \
        /ansible/haproxy-upgrade-playbook.yml
    EOT
  }
}

resource "null_resource" "ansible_haproxy" {
  depends_on = [
    null_resource.ansible_haproxy_upgrade,
    null_resource.ansible_master
  ]

  provisioner "local-exec" {
    quiet   = true
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_FORCE_COLOR=True \
      ansible-playbook \
        -i "${local.haproxy.connection_ip}," \
        --extra-vars "node_ip=${local.haproxy.private_ip}" \
        --extra-vars "{ "ips" : [${local.cluster_ips}]}" \
        /ansible/haproxy-playbook.yml
    EOT
  }
}

locals {
  haproxy = {
    name          = opennebula_virtual_machine.haproxy.name
    private_ip    = opennebula_virtual_machine.haproxy.nic[0].computed_ip
    public_ip     = lookup(local.ip_publica, opennebula_virtual_machine.haproxy.nic[0].computed_ip, "")
    connection_ip = (local.ansible.connect_to_public_ip ?
      lookup(local.ip_publica, opennebula_virtual_machine.haproxy.nic[0].computed_ip, "") :
      opennebula_virtual_machine.haproxy.nic[0].computed_ip)
  }
}

locals {
  ssh_proxy = local.ansible.connect_to_public_ip ? "'-o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@${local.haproxy.connection_ip}\"'" : "''"
}

output "haproxy" {
  value = local.haproxy
}
