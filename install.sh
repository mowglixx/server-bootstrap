#!/usr/bin/env bash

DOCKER_COMPOSE_VERSION='2.2.2'

if [ $(whoami) != 'root' ]; then
  echo "Please run as root"
else

  # do a little update
  apt update
  apt upgrade -y
  
  # secure ssh (see sshaudit.com)
  rm /etc/ssh/ssh_host_*
  ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
  ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
  awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
  mv /etc/ssh/moduli.safe /etc/ssh/moduli
  sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config
  echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
  systemctl restart ssh

  # add docker's gpg key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  

  # remove the bad stuff
  apt purge docker docker-engine docker.io containerd runc -y
  # install mainline
  add-apt-repository ppa:cappelikan/ppa
  apt update

  # installing all the good stuff
  apt install software-properties-common build-essential ca-certificates gnupg curl lsb-release gcc make mainline docker-ce docker-ce-cli containerd.io -y

  # docker-compose
  curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  # install latest mainline kernel
  mainline --install-latest --yes
  read -n 1 -s -r -p "Press any key to reboot or Ctrl+C to cancel"
  reboot
fi