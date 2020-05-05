variable "exoscale_key" {
  description = "Exoscale API key"
}

variable "exoscale_secret" {
  description = "Exoscale API secret"
}

variable "exoscale_zone" {
  description = "Exoscale zone"
}

variable "instance_size" {
  default = "Micro"
  description = "Exoscale instance size"
}

variable "disk_size" {
  type = number
  default = 10
  description = "Disk size in GB"
}

variable "security_group" {
  default = "default"
  description = "Security group name"
}

variable "hostname" {
  default = ""
  description = "Host name"
}

variable "ssh_port" {
  default = 12222
  type = number
  description = "SSH port (do not set to 22)"
}

variable "server_admin_users" {
  description = "Server admin users and their SSH key"
  type = map(string)
}