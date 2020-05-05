output "host_key_rsa_fingerprint" {
  value = tls_private_key.host-rsa.public_key_fingerprint_md5
}

output "host_key_rsa_pubkey" {
  value = tls_private_key.host-rsa.public_key_openssh
}
