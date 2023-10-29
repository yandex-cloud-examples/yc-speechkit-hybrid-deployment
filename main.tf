####
# PROVIDERS
####

terraform {
  required_version = ">= 1.0"
  required_providers {
    # https://registry.terraform.io/providers/yandex-cloud/yandex
    # https://www.terraform.io/docs/providers/yandex/index.html
    # https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.80"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "yandex" {
  # (next variables announced via environment)
  #token = "XX...XXX"
  #cloud_id = "XXXXXXXXXXXXXXXXXXXX"
  #folder_id = "XXXXXXXXXXXXXXXXXXXX"
}

####
# DATASOURCES
####

data "yandex_client_config" "client" {}

####
# COMPUTE IMAGE
####

data "yandex_compute_image" "image_container_optimized_gpu" {
  family = "container-optimized-image-gpu"
}

####
# SSH KEYS
###

resource "tls_private_key" "ssh_auto_id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

####
# OUTPUTS
####

output "yc-gpu-v100-docker-stt-tts-ext" {
  value = "${yandex_compute_instance.this.network_interface.*.nat_ip_address}"
}
