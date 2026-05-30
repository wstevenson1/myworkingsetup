# Installation Guide

## Prerequisites

- Docker and Docker Compose installed on the host machine.
- Git available to clone the repository.
- Optional: Ansible installed locally if you want to run the playbook outside the container.

## Clone the repository

```bash
git clone <repo-url> /path/to/myworkingsetup
cd /path/to/myworkingsetup
```

## Run the playbook via Docker

Use Docker Compose to build the container and execute the Ansible playbook:

```bash
docker compose up --build
```

This will:

- build a container image with Ansible installed
- run `ansible-playbook -i inventory/hosts playbook.yml`
- configure PostgreSQL 14 and OpenSSH
- deploy the portable Bash configuration files

## Local execution

If you already have Ansible available locally, run:

```bash
ansible-playbook -i inventory/hosts playbook.yml
```

## SSH access

The target system will configure `sshd` to listen on port `2222`.

If you are using the Docker container, map port `2222` through Docker Compose or via `docker run`.

## Files used for environment replication

- `cli_inventory.txt` — discovered CLI utilities from `/usr/local/bin` and `~/.local/bin`
- `homebrew_formulae.txt` — Homebrew-installed CLI formulae only
- `python_packages.txt` — installed Python packages
- `go_packages.txt` — installed Go binaries/module references
- `rust_packages.txt` — installed Rust tools via `cargo install`
- `prompt.md` — current requirement summary

## Notes

- The playbook is built to work on both Ubuntu and Fedora-style Linux hosts.
- It uses native `apt` or `dnf` package modules where possible.
- The Bash configuration is intended to be Linux-portable and avoids macOS-only paths.
- PostgreSQL and SSH services are enabled and started by the playbook.
