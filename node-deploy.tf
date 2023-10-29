####
# COMPUTE NODES
####

resource "yandex_compute_instance" "this" {

  name = "sk-hybrid-compose-example-${local.RES_SUFFIX}"
  zone = "ru-central1-a"
  folder_id = local.FOLDER_ID

  # (Intel Cascade Lake with GPU Nvidia Tesla V100)
  platform_id = "gpu-standard-v2"
  resources {
    cores = 16
    memory = 96
    core_fraction = 100
    gpus = 2
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.image_container_optimized_gpu.id}"
      size = "${var.DISK_SIZE}"
      type = "network-hdd"
    }
  }
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }

  network_interface {
    nat = true
    ipv4 = true
    subnet_id = yandex_vpc_subnet.this.id
    security_group_ids = [
      yandex_vpc_security_group.this.id
    ]
  }

  metadata = {
    serial-port-enable = 1
    user-data = templatefile("${path.module}/templates/cloudinit_config.tpl", {
      HOST_NAME = "sk-hybrid-compose-example-${local.RES_SUFFIX}"
      HOST_DOMAIN = var.DNS_ZONE_NAME
      USER_NAME = var.USER_NAME
      PUB_SSH_KEY_AUTO = trimspace(tls_private_key.ssh_auto_id_rsa.public_key_openssh)
      PUB_SSH_KEY_USER = file("${path.module}/keys/ssh-user-id-rsa.pub")
    })
    network_config = templatefile("${path.module}/templates/network_config.tpl", {
      IF_NAME = var.IF_NAME
    })
  }

  scheduling_policy {
    preemptible = var.NODES_GPU_INTERRUPTIBLE
  }

  allow_stopping_for_update = true
}

####
# DEPLOYING VARS
####

variable "COMPOSE_V100_STT_TTS" {
  type = string
  default =  <<EOF
version: '3'
services:
  envoy:
    container_name: envoy
    network_mode: host
    image: $CR_ENDPOINT/$CR_REGISTRY_ID/release/envoy:$SKH_VER
    environment:
      - TZ=UTC
      - ENVOY_UID=0
      - UPSTREAM_ASR_PROXY_PORT=8080
      - UPSTREAM_TTS_PROXY_PORT=9080
      - LOGGING_LEVEL=INFO
    #ports:
    #  - 8080:8080
    #  - 9080:9080
    restart: always

  license-server:
    container_name: license-server
    network_mode: host
    image: $CR_ENDPOINT/$CR_REGISTRY_ID/release/license_server:$SKH_VER
    environment:
      - TZ=UTC
      - UPSTREAM_ASR_REGISTRATIONS_SERVER_PORT=8087
      - UPSTREAM_TTS_REGISTRATIONS_SERVER_PORT=9087
      - LICENSE_MODE=billing_agent
      - LOGGING_LEVEL=INFO
      - STATIC_API_KEY=$BILLING_STATIC_API_KEY 
    #ports:
    #  - 8087:8087
    #  - 9087:9087
    volumes:
      - ./swaydb:/var/swaydb:z
    restart: always

  stt-server-gpu-v100:
    container_name: stt-server-gpu-v100
    network_mode: host
    privileged: true
    image: $CR_ENDPOINT/$CR_REGISTRY_ID/release/stt/v100/stt_server:$SKH_VER
    environment:
      - TZ=UTC
      - LICENSE_SERVICE_ENDPOINTS=0.0.0.0:8087
      - SERVICE_HOST=0.0.0.0
      - SERVICE_PORT=17880
      - UNISTAT_PORT=17882
      - CUDA_VISIBLE_DEVICES=0
      - NVIDIA_VISIBLE_DEVICES=0
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
      - LD_LIBRARY_PATH=/usr/local/cuda-host-compat
      - LOGGING_LEVEL=INFO
    #ports:
    #  - 17880:17880
    #  - 17882:17882
    volumes:
      - /usr/lib/x86_64-linux-gnu/libcuda.so:/usr/local/cuda-host-compat/libcuda.so:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ["0"]
              capabilities: [gpu]
    restart: always

  tts-server-gpu-v100:
    container_name: tts-server-gpu-v100
    network_mode: host
    privileged: true
    image: $CR_ENDPOINT/$CR_REGISTRY_ID/release/tts/v100/tts_server:$SKH_VER
    environment:
      - TZ=UTC
      - LICENSE_SERVICE_ENDPOINTS=0.0.0.0:9087
      - SERVICE_HOST=0.0.0.0
      - SERVICE_PORT=17980
      - UNISTAT_PORT=17982
      - CUDA_VISIBLE_DEVICES=1
      - NVIDIA_VISIBLE_DEVICES=1
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
      - LD_LIBRARY_PATH=/usr/local/cuda-host-compat
      - LOGGING_LEVEL=INFO
    #ports:
    #  - 17980:17980
    #  - 17982:17982
    volumes:
      - /usr/lib/x86_64-linux-gnu/libcuda.so:/usr/local/cuda-host-compat/libcuda.so:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ["1"]
              capabilities: [gpu]
    restart: always
EOF
}

variable "COMPOSE_ENV" {
  type = string
  default =  <<EOF
CR_ENDPOINT=
CR_REGISTRY_ID=
BILLING_STATIC_API_KEY=
SKH_VER=
EOF
}

####
# DEPLOYING EXEC
####

resource "null_resource" "this" {

  connection {
    type = "ssh"
    host = "${yandex_compute_instance.this.network_interface.0.nat_ip_address}"
    user = "${var.USER_NAME}"
    private_key = tls_private_key.ssh_auto_id_rsa.private_key_openssh
  }

  provisioner "file" {
    content = "${var.COMPOSE_V100_STT_TTS}"
    destination = "/home/${var.USER_NAME}/docker-compose.yml"
  }

  provisioner "file" {
    content = "${var.COMPOSE_ENV}"
    destination = "/home/${var.USER_NAME}/.env"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.USER_NAME}",
      "sed -i \"s#^CR_ENDPOINT=.*#CR_ENDPOINT=${var.CR_ENDPOINT}#\" ./.env",
      "sed -i \"s#^CR_REGISTRY_ID=.*#CR_REGISTRY_ID=${var.CR_REGISTRY_ID}#\" ./.env",
      "sed -i \"s#^BILLING_STATIC_API_KEY=.*#BILLING_STATIC_API_KEY=${var.BILLING_STATIC_API_KEY}#\" ./.env",
      "sed -i \"s#^SKH_VER=.*#SKH_VER=${var.SKH_VER}#\" ./.env"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.USER_NAME}",
      "mkdir -p ./.docker",
      "rm -f ./.docker/config.json",
      "docker login --username iam --password ${local.CR_IAM_TOKEN} ${var.CR_ENDPOINT}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.USER_NAME}",
      "docker-compose down",
      "sleep 3",
      "cat /proc/driver/nvidia/version || true",
      "nvidia-container-cli info",
      "echo 'docker-compose pull ...'",
      "docker-compose pull --quiet",
      "echo 'docker-compose up ...'",
      "docker-compose up -d --force-recreate --remove-orphans",
      "sleep 7",
      "docker ps -a",
    ]
  }

  triggers = {
    compose_changed = md5(var.COMPOSE_V100_STT_TTS)
    node_id_changed = yandex_compute_instance.this.id
  }

  depends_on = [yandex_compute_instance.this]
}
