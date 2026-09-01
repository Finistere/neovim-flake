#!/bin/sh

set -eu

colima_profile=nvim-builder
docker_context=colima-nvim-builder
nix_image=${NVIM_NIX_IMAGE:-ghcr.io/nixos/nix:2.35.1}
local_source=
if [ -n "${NVIM_FLAKE:-}" ]; then
    flake_reference=$NVIM_FLAKE
else
    local_source=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
    flake_reference=path:/source
fi
bundler_reference=${NVIM_BUNDLER:-${flake_reference}#nvim-portable}

temporary_directory=
build_container=
remote_upload=
remote_upload_exists=false
colima_started=false

usage() {
    echo "Usage: $0 <ssh-target> [package]" >&2
    echo "       package defaults to nvim-minimal; nvim selects the full package" >&2
}

cleanup() {
    exit_code=$?
    set +e

    if [ "$remote_upload_exists" = true ]; then
        ssh "$ssh_target" "rm -f '$remote_upload'" >/dev/null 2>&1
    fi

    if [ -n "$build_container" ]; then
        docker --context "$docker_context" rm --force "$build_container" >/dev/null 2>&1
    fi

    if [ -n "$temporary_directory" ]; then
        rm -rf -- "$temporary_directory"
    fi

    if [ "$colima_started" = true ]; then
        echo "Stopping Colima profile $colima_profile..."
        colima --profile "$colima_profile" stop
    fi

    exit "$exit_code"
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
    exit 2
fi

ssh_target=$1
package=${2:-nvim-minimal}

case $package in
    '' | *[!a-zA-Z0-9._-]*)
        echo "Invalid package name: $package" >&2
        exit 2
        ;;
esac

for command_name in colima docker ssh scp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
done

if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
    echo "This script must run on an Apple Silicon Mac." >&2
    exit 1
fi

colima_home=${COLIMA_HOME:-$HOME/.colima}
colima_config="$colima_home/$colima_profile/colima.yaml"
if [ ! -e "$colima_config" ]; then
    echo "Missing Colima profile configuration: $colima_config" >&2
    echo "Apply Zelenka's dotfiles configuration before running this script." >&2
    exit 1
fi

remote_platform=$(
    ssh "$ssh_target" 'printf "%s:%s\n" "$(uname -s)" "$(uname -m)"'
)
remote_os=${remote_platform%%:*}
remote_arch=${remote_platform#*:}

if [ "$remote_os" != Linux ]; then
    echo "The target must run Linux; detected: $remote_os" >&2
    exit 1
fi

case $remote_arch in
    x86_64)
        target_system=x86_64-linux
        docker_platform=linux/amd64
        nix_volume=nvim-builder-nix-amd64
        ;;
    aarch64 | arm64)
        target_system=aarch64-linux
        docker_platform=linux/arm64
        nix_volume=nvim-builder-nix-arm64
        ;;
    *)
        echo "Unsupported target architecture: $remote_arch" >&2
        exit 1
        ;;
esac

if ! colima --profile "$colima_profile" status >/dev/null 2>&1; then
    echo "Starting Colima profile $colima_profile..."
    if ! colima --profile "$colima_profile" start \
        --activate=false \
        --save-config=false; then
        echo "Failed to start Colima profile $colima_profile." >&2
        echo "Inspect it with: colima --profile $colima_profile status" >&2
        exit 1
    fi
    colima_started=true
fi

if ! docker --context "$docker_context" info >/dev/null 2>&1; then
    echo "Docker context $docker_context is not available." >&2
    exit 1
fi

docker --context "$docker_context" volume create \
    --label dev.finistere.neovim-builder.cache=true \
    --label "dev.finistere.neovim-builder.platform=$target_system" \
    "$nix_volume" >/dev/null

temporary_root=${XDG_CACHE_HOME:-$HOME/.cache}
mkdir -p "$temporary_root"
temporary_directory=$(mktemp -d "$temporary_root/nvim-bundle.XXXXXX")
bundle_path="$temporary_directory/nvim"
flake_package="${flake_reference}#packages.${target_system}.${package}"

echo "Bundling $flake_package in $docker_platform..."
build_container=$(
    docker --context "$docker_context" create \
        --platform "$docker_platform" \
        --volume "$nix_volume:/nix" \
        --env "FLAKE_PACKAGE=$flake_package" \
        --env "BUNDLER_REFERENCE=$bundler_reference" \
        --entrypoint /bin/sh \
        "$nix_image" \
        -eu -c '
        # Rosetta cannot install the seccomp BPF program used by this filter.
        nix --extra-experimental-features "nix-command flakes" \
            --no-filter-syscalls \
            bundle \
            --bundler "$BUNDLER_REFERENCE" \
            --out-link /tmp/nvim-bundle \
            "$FLAKE_PACKAGE"
        cp -L /tmp/nvim-bundle/bin/nvim /tmp/nvim
        chmod 0755 /tmp/nvim
    '
)
if [ -n "$local_source" ]; then
    docker --context "$docker_context" cp "$local_source/." "$build_container:/source"
fi
docker --context "$docker_context" start --attach "$build_container"
docker --context "$docker_context" cp "$build_container:/tmp/nvim" "$bundle_path"
docker --context "$docker_context" rm "$build_container" >/dev/null
build_container=

if [ ! -x "$bundle_path" ]; then
    echo "The bundle was not copied to $bundle_path." >&2
    exit 1
fi

remote_upload=".local/bin/.nvim-upload-$$"
echo "Uploading bundle to $ssh_target..."
ssh "$ssh_target" 'mkdir -p .local/bin'
remote_upload_exists=true
scp "$bundle_path" "$ssh_target:$remote_upload"

echo "Validating bundle on $ssh_target..."
ssh "$ssh_target" "chmod 0755 '$remote_upload' && '$remote_upload' --version"

ssh "$ssh_target" "mv -f '$remote_upload' .local/bin/nvim"
remote_upload_exists=false

echo "Installed $package as ~/.local/bin/nvim on $ssh_target"
