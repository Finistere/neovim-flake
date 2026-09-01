#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 <ssh-target> [package]" >&2
    echo "       package defaults to nvim-minimal; nvim selects the full package" >&2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 2
fi

ssh_target=$1
package=${2:-nvim-minimal}

if [[ ! $package =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Invalid package name: $package" >&2
    exit 2
fi

for command_name in nix ssh scp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
done

if [[ $(uname -s) != Linux ]]; then
    echo "This script must run on Linux because 'nix bundle' only supports Linux." >&2
    exit 1
fi

read -r remote_os remote_arch < <(
    ssh "$ssh_target" 'printf "%s %s\n" "$(uname -s)" "$(uname -m)"'
)

if [[ $remote_os != Linux ]]; then
    echo "The target must run Linux; detected: $remote_os" >&2
    exit 1
fi

case $remote_arch in
    x86_64)
        target_system=x86_64-linux
        ;;
    aarch64 | arm64)
        target_system=aarch64-linux
        ;;
    *)
        echo "Unsupported target architecture: $remote_arch" >&2
        exit 1
        ;;
esac

temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT

bundle_path="$temporary_directory/nvim"
flake_package=".#packages.${target_system}.${package}"

echo "Bundling $flake_package for $ssh_target..."
nix bundle "$flake_package" --out-link "$bundle_path"

remote_upload=".local/bin/.nvim-upload-$$"
echo "Installing as ~/.local/bin/nvim on $ssh_target..."
ssh "$ssh_target" 'mkdir -p .local/bin'
scp "$bundle_path" "$ssh_target:$remote_upload"
ssh "$ssh_target" \
    "chmod 0755 '$remote_upload' && mv -f '$remote_upload' .local/bin/nvim"

echo "Installed $package as ~/.local/bin/nvim on $ssh_target"
