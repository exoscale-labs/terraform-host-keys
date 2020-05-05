// region Host keys
resource "tls_private_key" "host-rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "tls_private_key" "host-ecdsa" {
  algorithm = "ECDSA"
}
// endregion

// region Initial SSH key for provisioning (removed after instance creation)
resource "tls_private_key" "initial" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "exoscale_ssh_keypair" "initial" {
  name = "${var.hostname}initial"
  public_key =  replace(tls_private_key.initial.public_key_openssh, "\n", "")
}
// endregion