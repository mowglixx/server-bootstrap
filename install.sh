#!/usr/bin/env bash

PORTAINER_VERSION=2.9.3
DOCKER_COMPOSE_VERSION=2.2.2
# comment this out if IPv6 is enabled on your host
DISABLE_IPV6='true'

if [ $(whoami) != 'root' ]; then
  echo "Please run as root"

  else

# do a little update

# secure ssh (see sshaudit.com)
rm /etc/ssh/ssh_host_*
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
mv /etc/ssh/moduli.safe /etc/ssh/moduli
sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config
echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
systemctl restart ssh

# installing all the good stuff
apt purge docker docker-engine docker.io containerd runc -y
apt install software-properties-common build-essential ca-certificates gnupg curl lsb-release gcc make -y

# add docker's gpg key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# add docker repos to sources and update apt
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update

# install docker
apt install docker-ce docker-ce-cli containerd.io docker-compose
curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# run portainer with no ports exposed
docker volume create portainer_data
docker run -d --expose 8000 --expose 9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data cr.portainer.io/portainer/portainer-ce:$PORTAINER_VERSION

# run nginx proxy manager
docker volume create nginx_data
docker run -d -p 80:80 -p 81:81 -p 443:443 -p 8080:8080 -p 8443:8443 --name nginx-proxy-manager --restart=always -v nginx_data:/data -v /etc/letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest