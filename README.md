# server-bootstrap

> Quick script to get a new VPS (Ubuntu 20.04) up and running asap

## Lore

*"...I got fed up of f\*\*king up my server and having to do all this over and over so I made this script..."*

\- Dan, 2021

### whats included?

- installs the latest mainline kernel
- hardens SSH server as per sshaudit.com
- apt install:
  - software-properties-common
  - build-essential
  - ca-certificates
  - gnupg-
  - curl
  - lsb-release
  - gcc
  - make
  - mainline
  - docker-ce
  - docker-ce-cli
  - containerd.io
- docker-compose

## Docker Compose versions

Docker compose needs its version number changing at the top of the file when an update comes out

I might not update that so keep an eye on [the compose releases page](https://github.com/docker/compose/releases/)
