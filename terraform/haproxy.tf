resource "opennebula_virtual_machine" "haproxy" {

  depends_on = [
    opennebula_virtual_machine.master
  ]

  template_id = data.opennebula_template.template.id

  name = "kube-haproxy"

  cpu    = local.opennebula.limits.haproxy.cpu
  vcpu   = local.opennebula.limits.haproxy.vcpu
  memory = local.opennebula.limits.haproxy.memory

  context = {
    NETWORK        = "YES"
    SET_HOSTNAME   = "$NAME"
    SSH_PUBLIC_KEY = join("\n", [var.SSH_PUBLIC_KEY, file("~/.ssh/id_rsa.pub")])
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

resource "null_resource" "ansible_haproxy" {
  depends_on = [
    null_resource.hosts_haproxy,
    null_resource.ansible_master
  ]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook \
        -i "${local.haproxy.connection_ip}," \
        /ansible/haproxy-playbook.yml \
        --extra-vars "node_ip=${local.haproxy.private_ip}" \
        --extra-vars "{ "ips" : [${local.cluster_ips}]}"
    EOT
  }
}

locals {
  haproxy = {
    name          = opennebula_virtual_machine.haproxy.name
    private_ip    = opennebula_virtual_machine.haproxy.nic[0].computed_ip
    public_ip     = lookup(local.ip_publica, opennebula_virtual_machine.haproxy.nic[0].computed_ip, "")
    connection_ip = local.ansible.connect_to_public_ip ? lookup(local.ip_publica, opennebula_virtual_machine.haproxy.nic[0].computed_ip, "") : opennebula_virtual_machine.haproxy.nic[0].computed_ip
  }
}

output "haproxy" {
  value = local.haproxy
}
