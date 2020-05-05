# Provisioning SSH host keys with Terraform

This example shows how to pre-generate SSH host keys and provision them into an Ubuntu 18.04 instance.

## Pros/Cons

- **Pro:** Provides a reliable host key from the first connection
- **Con:** Private host key will be visible from the metadata server. Make sure you don't have SSRF / implement firewalls on
  the instance.  
- **Con:** Private host key will be present in the Terraform state file.

## Concept

The basic idea is to use the [tls_private_key](https://www.terraform.io/docs/providers/tls/r/private_key.html) 
resource to create an RSA, and an ECDSA private key:

```hcl-terraform
resource "tls_private_key" "host-rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}
resource "tls_private_key" "host-ecdsa" {
  algorithm = "ECDSA"
}
```

Then the private key is provisioned from the user data in the instance:

```hcl-terraform
resource "exoscale_compute" "instance" {
  //...
  user_data = <<EOF
#!/bin/bash

set -e

#...

# region SSH host key
# Inject host keys
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
EOF
}
```