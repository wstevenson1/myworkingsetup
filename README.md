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
- `rust_packages.txt`, `go_packages.txt`, `python_packages.txt` - `cargo install
  --list`, `module@version`, and `pip freeze` dumps captured on the Mac; both
  playbooks install these via `roles/language_packages/` once Homebrew has
  provided cargo/go/pip. `cargo_skip.txt`, `go_packages_skip.txt` and
  `python_packages_skip.txt` list entries excluded from those install loops
  because they fail the same way on every run: no reproducible source (a local
  path cargo recorded), macOS-only (pyobjc, macpow), a library mis-captured as
  installable, a command that lives in a subpackage of the recorded path, or a
  tool Homebrew already provides (mise).
- `roles/language_packages/` - shared cargo/go/pip install tasks, included by
  both playbooks so that logic exists in one place
- `roles/zsh/` - shared tasks that deploy the portable zsh environment
  (`~/.zshrc`, the SQLite-history and `logr` zsh ports, and the vendored
  `zsh-autosuggestions` v0.7.1). `~/.zshrc` is a hand-portable rewrite of the
  macOS `~/.zshrc`, the same way `files/bashrc` is of `~/.bashrc`. It does not
  require Oh My Zsh (an existing `~/.oh-my-zsh` is sourced if present) and does
  not change the login shell.
- `roles/starship/` - shared task that deploys `~/.config/starship.toml`. The
  `starship` binary comes from `homebrew_formulae.txt`; `roles/zsh/`'s rc runs
  `starship init zsh`, so the prompt is wired up for zsh only (`files/bashrc`
  keeps its own `PS1`).
- `Dockerfile` and `docker-compose.yml` - run the playbook inside a container
- `files/` - bash config templates, the tmux config, the vim config, the
  history helper script, and vendored third-party helpers so provisioning never
  has to reach GitHub: `bash-preexec.sh` (upstream tag 0.7.0) and `fasd/`
  (clvv/fasd tag 1.0.1). The zsh counterparts live under `roles/zsh/files/`
  (including vendored `zsh-autosuggestions` v0.7.1).

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
- `~/.vimrc` is deployed verbatim from `files/vimrc` (an existing file is backed
  up first). It enables `backup`/`writebackup`, so the playbook pre-creates the
  two directories it points at: `~/.vim_backups/` (dated backups) and
  `~/.vim/temp` (swap files).
- `~/.zshrc` is deployed from `roles/zsh/files/zshrc` (an existing file is
  backed up first). It mirrors `files/bashrc` feature for feature in zsh idiom,
  reuses the same `~/.hist.db` SQLite history database, and every tool init is
  guarded. No `~/.zprofile`/`~/.zshenv` is written - zsh reads `~/.zshrc` for
  login shells too and the rc builds `PATH` itself. The login shell is left
  unchanged; run `chsh -s "$(command -v zsh)"` yourself to switch.
- `~/.config/starship.toml` is deployed from `roles/starship/files/`. Starship
  is initialized only by `~/.zshrc`; a plain `bash` session keeps the
  `[\t][\u@\h:\w]$` prompt from `files/bashrc`.
- `sshd` will be configured to listen on port `2222` with password authentication enabled.
