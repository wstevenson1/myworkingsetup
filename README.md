# Dev Environment Bootstrap

This repository contains a generic Ansible-based bootstrap for a Linux development environment. It is intended to be used from a cloned repo or a container and to install the requested utilities, user bash setup, PostgreSQL 14, and OpenSSH configured to listen on port `2222`.

## What is included

- `playbook.yml` - main Ansible playbook to install packages and deploy bash startup files
- `inventory/hosts` - localhost inventory for container/VM bootstrap
- `ansible.cfg` - Ansible configuration for local execution
- `cli_inventory.txt` - discovered CLI utilities from `/usr/local/bin` and `~/.local/bin`
- `homebrew_formulae.txt` - Homebrew-installed CLI formulae only
- `Dockerfile` and `docker-compose.yml` - run the playbook inside a container
- `files/` - bash config templates and history helper script

## Quick start

```bash
git clone <repo-url> /path/to/myworkingsetup
cd /path/to/myworkingsetup
docker compose up --build
```

The container will build, execute the Ansible playbook, and then keep `sshd` running on port `2222`.

## Direct local execution

If you already have Ansible installed on the target machine:

```bash
cd /path/to/myworkingsetup
ansible-playbook -i inventory/hosts playbook.yml
```

## Notes

- The playbook is designed to work on Ubuntu and Fedora family systems.
- PostgreSQL installation attempts `postgresql-14` on Debian/Ubuntu and falls back to `postgresql` if version 14 is unavailable in the local apt sources.
- The bash startup configuration is Linux-portable and strips macOS-specific Homebrew/OrbStack/Rancher Desktop paths.
- `sshd` will be configured to listen on port `2222` with password authentication enabled.
