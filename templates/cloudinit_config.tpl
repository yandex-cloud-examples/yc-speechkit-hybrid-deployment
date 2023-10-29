#cloud-config
preserve_hostname: false
hostname: ${HOST_NAME}
fqdn: ${HOST_NAME}
manage_etc_hosts: true
users:
  - name: ${USER_NAME}
    shell: /bin/bash
    groups: sudo,docker
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${PUB_SSH_KEY_AUTO}
      - ${PUB_SSH_KEY_USER}
disable_root: true
ssh_pwauth: true
growpart:
  mode: auto
  devices: ['/']
# (next written to /var/log/cloud-init-output.log)
final_message: "The cloud-init user script is finish, after $UPTIME seconds"
