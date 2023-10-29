####
# NETWORKS
####

resource "yandex_vpc_network" "this" {
  name = "sk-hybrid-compose-example-${local.RES_SUFFIX}-network"
}

resource "yandex_vpc_subnet" "this" {
  name           = "sk-hybrid-compose-example-${local.RES_SUFFIX}-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.210.0.0/24"]
  folder_id   = local.FOLDER_ID
  dhcp_options {
    domain_name = local.DNS_ZONE_NAME
  }
}

####
# CLOUD DNS
####

resource "yandex_dns_zone" "sk_hybrid_compose_demo_zone_0" {
  name        = "sk-hybrid-compose-example-${local.RES_SUFFIX}-zone"
  description = "Zone for Docker Compose Example Stand of SK-Hybrid"
  folder_id   = local.FOLDER_ID

  zone             = local.DNS_ZONE_NAME
  public           = false
  private_networks = [yandex_vpc_network.this.id]
}

####
# SECURITY GROUPS
####

resource "yandex_vpc_security_group" "this" {
  description = "SG for SK-Hybrid nodes"
  name        = "sk-hybrid-compose-example-${local.RES_SUFFIX}-sg"
  network_id  = yandex_vpc_network.this.id
  folder_id   = local.FOLDER_ID

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    v6_cidr_blocks = []
    port           = 22
  }

  ingress {
    protocol          = "ANY"
    description       = "Any interactions within the security group are allowed."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "STT"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }

  ingress {
    protocol       = "TCP"
    description    = "TTS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9080
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
