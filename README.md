# Dev Environment Bootstrap

This repository contains a generic Ansible-based bootstrap for a Linux development environment. It is intended to be used from a cloned repo or a container and to install the requested utilities, user bash setup, PostgreSQL 14, and OpenSSH configured to listen on port `2222`.

## What is included

- `playbook.yml` - main Ansible playbook to install packages and deploy bash startup files
- `wsl_playbook.yml` - WSL variant: no sudo, no fact gathering, Homebrew as the only
  package manager. Deploys the same dotfiles; everything needing root is dropped.
  Because `~/.bashrc` is read-only on WSL, the portable rc is written to
  `~/.bash_aliases` (which `~/.bashrc` sources), and `~/.bash_profile` is only
  created when no login-shell dotfile already exists.
  Run it with `ansible-playbook -i inventory/hosts wsl_playbook.yml` (no `-K`).
- `inventory/hosts` - localhost inventory for container/VM bootstrap
- `ansible.cfg` - Ansible configuration for local execution
- `cli_inventory.txt` - discovered CLI utilities from `/usr/local/bin` and `~/.local/bin`
- `homebrew_formulae.txt` - Homebrew-installed CLI formulae only
- `Dockerfile` and `docker-compose.yml` - run the playbook inside a container
- `files/` - bash config templates, the tmux config, and the history helper script

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
ansible-playbook -i inventory/hosts playbook.yml -K
```

The playbook uses `become: yes`, so `-K` prompts once for your sudo password.
Omit it only if the account has passwordless sudo; without it the run fails at
`Gathering Facts` with "Timed out waiting for become success".

## Notes

- The playbook is designed to work on Ubuntu and Fedora family systems.
- PostgreSQL installation attempts `postgresql-14` on Debian/Ubuntu and falls back to `postgresql` if version 14 is unavailable in the local apt sources.
- The bash startup configuration is Linux-portable and strips macOS-specific Homebrew/OrbStack/Rancher Desktop paths.
- `~/.tmux.conf` is deployed from `files/tmux.conf.j2`. Its `default-command` is
  resolved per host: the Linuxbrew bash when one is installed, `/bin/bash` otherwise.
- `sshd` will be configured to listen on port `2222` with password authentication enabled.
