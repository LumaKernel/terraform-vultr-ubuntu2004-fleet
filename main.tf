terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.3.0"
    }
  }
}

provider "vultr" {
  api_key     = var.vultr_api_key
  rate_limit  = 700
  retry_limit = 3
}

resource "vultr_firewall_group" "fw" {
  description = var.project_name
}

resource "vultr_firewall_rule" "fw_allow_ssh_v4" {
  firewall_group_id = vultr_firewall_group.fw.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "22"
  notes             = "allow ssh ipv4 from anywhere"
}

resource "vultr_firewall_rule" "fw_allow_ssh_v6" {
  firewall_group_id = vultr_firewall_group.fw.id
  protocol          = "tcp"
  ip_type           = "v6"
  subnet            = "::0"
  subnet_size       = 0
  port              = "22"
  notes             = "allow icmp ipv6 from anywhere"
}

resource "vultr_firewall_rule" "fw_allow_icmp_v4" {
  firewall_group_id = vultr_firewall_group.fw.id
  protocol          = "icmp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "allow ssh ipv4 from anywhere"
}

resource "vultr_firewall_rule" "fw_allow_icmp_v6" {
  firewall_group_id = vultr_firewall_group.fw.id
  protocol          = "icmp"
  ip_type           = "v6"
  subnet            = "::0"
  subnet_size       = 0
  notes             = "allow icmp ipv6 from anywhere"
}

resource "vultr_private_network" "private_network" {
  description    = var.project_name
  v4_subnet      = var.v4_subnet
  v4_subnet_mask = var.v4_subnet_mask
  region         = var.region
}

resource "vultr_startup_script" "setup_ubuntu2004" {
  name   = "setup-ubuntu2004"
  script = filebase64("files/setup_ubuntu2004.sh")
}

resource "vultr_instance" "hosts" {
  for_each          = var.instances
  backups           = "disabled"
  hostname          = each.value.hostname
  enable_ipv6       = true
  firewall_group_id = vultr_firewall_group.fw.id
  private_network_ids = [
    vultr_private_network.private_network.id,
  ]
  ssh_key_ids = var.ssh_key_ids
  script_id   = vultr_startup_script.setup_ubuntu2004.id
  region      = var.region
  os_id       = "387"
  plan        = each.value.plan
}

output "host_v4_list" {
  value = {
    for key in keys(var.instances)
    : key => vultr_instance.hosts[key].main_ip
  }
}

output "host_v6_list" {
  value = {
    for key in keys(var.instances)
    : key => vultr_instance.hosts[key].v6_main_ip
  }
}
