#!/usr/bin/env bash
set -euo pipefail

BASE_VENV="$HOME/.venv"
ORIGINAL_PATH="$PATH"
SALT_STATES="${HOME}/z/fm/anr"

function get_os_id() {
    cat /etc/os-release | grep -E '^ID=' | awk -F = '{print $2}'
}

function maybe_sudo() {
    cmd="$@"
    if [ $(id -u) -eq 0 ]
    then
        $cmd
    else
        sudo $cmd
    fi
}

function dnf_install() {
    maybe_sudo dnf install -y git python3-virtualenv
}

function apt_install() {
    maybe_sudo apt update
    maybe_sudo apt install -y git python3-virtualenv
}

function activate_venv() {
    venv="$1"

    venv_bin="${BASE_VENV}/${venv}/bin"
    export PATH="${venv_bin}:$PATH"
    export VIRTUAL_ENV="${BASE_VENV}/venv"
}

function deactivate_venv() {
    export PATH="$ORIGINAL_PATH"
    unset VIRTUAL_ENV
}

function venv_install_ansible() {
    python3 -m virtualenv --python $(which python3) "${BASE_VENV}/ansible"
    activate_venv ansible
    pip install ansible
    deactivate_venv ansible
}

function ansible_pull() {
    activate_venv ansible
    inventory="$(hostname),"
    ansible-pull -U https://github.com/femnad/casastrap.git -i "$inventory" init-salt.yaml
}

function install_packages() {
  os_id=$(get_os_id)

  case $os_id in
    fedora)
        dnf_install
        ;;
    debian|ubuntu)
        apt_install
        ;;
    *)
        echo "Unknown OS Id: $os_id"
        exit 1
        ;;
    esac
}

function salt_apply() {
    activate_venv salt
    pushd "$SALT_STATES"
    salt-ssh self-sudo state.apply all
    salt-ssh self state.apply all
    deactivate_venv salt
    popd
}

function main() {
    install_packages
    venv_install_ansible
    ansible_pull
    salt_apply
}

main
