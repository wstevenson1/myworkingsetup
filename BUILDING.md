# Rebuilding the vendored `d` binary

`files/bin/d-linux-{amd64,arm64}` are static musl builds of
`~/code/recentdirs` (Cargo package `mytool`), installed by the playbook as
`~/.local/bin/d`.

They are committed rather than built on the target because neither
provisioned host has a Rust toolchain, and the source repo has no remote to
clone from. **They do not rebuild themselves — after changing the recentdirs
source, redo this.**

## Prerequisites

macOS `clang` cannot link musl, and plain `zig cc` fails two ways (duplicate
`_start` on x86_64, unsupported `--fix-cortex-a53-843419` on aarch64).
`cargo-zigbuild` handles both:

```sh
brew install zig
cargo install cargo-zigbuild
rustup toolchain install stable
rustup +stable target add x86_64-unknown-linux-musl aarch64-unknown-linux-musl
```

Build with `+stable` explicitly: `clap_builder` requires edition2024
(Rust >= 1.85), so an older default toolchain fails to parse the manifest.

## Build and vendor

```sh
cd ~/code/recentdirs
cargo +stable zigbuild --release --target x86_64-unknown-linux-musl
cargo +stable zigbuild --release --target aarch64-unknown-linux-musl

cd ~/code/myworkingsetup
cp ~/code/recentdirs/target/x86_64-unknown-linux-musl/release/mytool files/bin/d-linux-amd64
cp ~/code/recentdirs/target/aarch64-unknown-linux-musl/release/mytool files/bin/d-linux-arm64
chmod 755 files/bin/d-linux-*
```

Confirm both are static before committing:

```sh
file files/bin/d-linux-*   # expect "statically linked" for each
```

# Updating the vendored `bash-preexec.sh`

`files/bash-preexec.sh` is committed rather than fetched at provision time:
some hosts reset the connection to `raw.githubusercontent.com`. Both playbooks
`copy` it to `~/.bash-preexec.sh`.

To move to a newer upstream release, pick the tag from
<https://github.com/rcaloras/bash-preexec/releases> and re-vendor it:

```sh
cd ~/code/myworkingsetup
curl -fsSL -o files/bash-preexec.sh \
  https://raw.githubusercontent.com/rcaloras/bash-preexec/<tag>/bash-preexec.sh
```

Then bump the `tag 0.7.0` note in the `Ensure bash-preexec helper is installed`
task comment in both `playbook.yml` and `wsl_playbook.yml`.
