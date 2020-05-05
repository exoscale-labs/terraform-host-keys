resource "exoscale_compute" "instance" {
  display_name = var.hostname
  disk_size = var.disk_size
  key_pair = exoscale_ssh_keypair.initial.name
  size = var.instance_size
  template = "Linux Ubuntu 18.04 LTS 64-bit"
  zone = var.exoscale_zone

  security_groups = [
    var.security_group
  ]

  user_data = <<EOF
#!/bin/bash

set -e

# region Users
function create_user() {
  useradd -m -s /bin/bash $1
  mkdir -p /home/$1/.ssh
  echo "$2" >/home/$1/.ssh/authorized_keys
  chown -R $1:$1 /home/$1
  gpasswd -a $1 sudo
  gpasswd -a $1 adm
}

# Enable passwordless sudo
sed -i -e 's/%sudo\s*ALL=(ALL:ALL)\s*ALL/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

#Create users
%{ for user,ssh_key in var.server_admin_users }
create_user ${user} "${ssh_key}"
%{ endfor }
# endregion

# region Updates
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y rsync htop tcpdump tcpflow unzip mc
# endregion

# region SSH host key
# Inject host keys
umask 077
echo '${tls_private_key.host-ecdsa.private_key_pem}' >/etc/ssh/ssh_host_ecdsa_key
echo '${tls_private_key.host-rsa.private_key_pem}' >/etc/ssh/ssh_host_rsa_key
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/' /etc/ssh/sshd_config
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/' /etc/ssh/sshd_config
# Remove unsupported keys (Terraform can't generate DSA and ED25519 keys)
rm /etc/ssh/ssh_host_dsa_key
rm /etc/ssh/ssh_host_ed25519_key
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key//' /etc/ssh/sshd_config
sed -i -e 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key//' /etc/ssh/sshd_config
# endregion

# region Disable password authentication
sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# endregion

# region SSH port change
ufw allow ${var.ssh_port}/tcp
sed -i -e 's/#Port 22/Port ${var.ssh_port}/' /etc/ssh/sshd_config
# endregion

# region Prevent Metadata server access
cat /etc/ufw/before.rules | perl -0pe "s/\n# don't delete the 'COMMIT' line or these rules won't be processed\nCOMMIT\n/
# prevent Exoscale metadata server access
-A ufw-before-output -m owner ! --uid-owner 0 -d 169.254.169.254 -j REJECT

# don't delete the 'COMMIT' line or these rules won't be processed
COMMIT
/"
# endregion

# region UFW
ufw enable
# endregion

# region Reboot
# Reboot to apply updates and restart SSH
reboot --reboot
# endregion
EOF

  connection {
    type = "ssh"
    agent = false
    user = self.username
    host = self.ip_address
    port = var.ssh_port
    private_key = tls_private_key.initial.private_key_pem
    host_key = tls_private_key.host-rsa.public_key_openssh
  }

  //Add further provisioners here

  //Delete initial SSH key
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo userdel -f -r ubuntu"
    ]
  }
}
