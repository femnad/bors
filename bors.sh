#!/usr/bin/env bash
set -euo pipefail

ANSIBLE_VENV="$HOME/.venv/ansible"

function get_os_id() {
    cat /etc/os-release | grep -E '^ID' | awk -F = '{print $2}'
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
    maybe_sudo apt install -y git python3-virtualnv
}

function activate_ansible_venv() {
    source "${ANSIBLE_VENV}/bin/activate"
}

function venv_install_ansible() {
    virtualenv "${ANSIBLE_VENV}"
    activate_ansible_venv
    pip install ansible
}

function ansible_pull() {
    activate_ansible_venv
    ansible_pull -U https://github.com/femnad/casastrap.git -i "$(hostname)," salt-init.yml
}

function install_packages() {
  os_id=$(get_os_id)

  case $os_id in
    fedora)
        dnf_install
        ;;
    debian)
        apt_install
        ;;
    *)
        echo "Unknown OS Id: $os_id"
        exit 1
        ;;
    esac

}

function main() {
    install_packages
    venv_install_ansible
    ansible_pull
}

main
