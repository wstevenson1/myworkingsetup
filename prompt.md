# Current Requirements

- Create a Git repository in `/Users/wstevenson/code/myworkingsetup` documenting a Linux dev environment bootstrap.
- Build an Ansible playbook that installs required packages on Ubuntu or Fedora.
- Ensure PostgreSQL 14 and OpenSSH are installed, enabled, and configured.
- Configure `sshd` to listen on port `2222` and allow password authentication.
- Replicate the user bash environment from the provided Mac-based dotfiles, stripping macOS-specific paths and keeping portable Linux-friendly config.
- Use the discovered CLI inventories from `/usr/local/bin`, `~/.local/bin`, and `~/.programs`, but install only a curated, reliably mappable set.
- Read package lists from the following exported files and use them as input for environment replication:
  - `python_packages.txt`
  - `go_packages.txt`
  - `rust_packages.txt`
  - `homebrew_formulae.txt` (Homebrew CLI formulae only)
- Provide Docker support with a `Dockerfile` and `docker-compose.yml` to run the Ansible playbook in a container.
- Include documentation, inventory, and helper files in the repository.
