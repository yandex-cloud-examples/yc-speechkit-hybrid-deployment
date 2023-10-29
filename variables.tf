####
# ENV VARS
####

variable "FOLDER_ID" {
  description = "Yandex-Cloud Folder-ID where resources will be created"
  type = string
  default = null
}

# DNS

variable "DNS_ZONE_NAME" {
  description = "Base domain name (level 1 of FQDN). Generated automatically, but can be redefined in variable file 'terrafrom.tfvars'"
  type = string
  default = null
}

# Compute Resources

variable "NODES_GPU_INTERRUPTIBLE" {
  description = "Enabling interruptible GPU-nodes mode"
  type = bool
  default = true
}

variable "USER_NAME" {
  type = string
  default = "terraform"
}

variable "DISK_SIZE" {
  type = string
  default = "128" # (in GB)
}

variable "IF_NAME" {
  type = string
  default = "eth0"
}

# Socker Compose Resources

# ( https://cloud.yandex.ru/en/docs/container-registry/operations/authentication )
variable "CR_ENDPOINT" {
  type = string
  default = "cr.yandex"
}

# ( https://cloud.yandex.com/en/docs/container-registry/concepts/repository )
variable "CR_REGISTRY_ID" {
  type = string
  default = null
}

# SK-Hybrid Resources

# ( https://cloud.yandex.ru/docs/iam/operations/sa/create-access-key )
variable "BILLING_STATIC_API_KEY" {
  type = string
  default = null
}

variable "SKH_VER" {
  type = string
  default = "0.20"
}

###
# COLLECTED ENV VARS
####

# Suffix to make resource names unique
resource "random_string" "suffix" {
  length = 5
  min_numeric = 2
  upper = false
  special = false
}

locals {
  FOLDER_ID = var.FOLDER_ID == null ? data.yandex_client_config.client.folder_id : var.FOLDER_ID
  CR_IAM_TOKEN = data.yandex_client_config.client.iam_token
  RES_SUFFIX = random_string.suffix.result
  DNS_ZONE_NAME = var.DNS_ZONE_NAME == null ? "sk-hybrid-example-${local.RES_SUFFIX}.local." : var.DNS_ZONE_NAME 
}
