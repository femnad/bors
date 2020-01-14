#!/usr/bin/env bash
set -euo pipefail

function get_os_id() {
    cat /etc/os-release | grep -E '^ID' | awk -F = '{print $2}'
}

function maybe_sudo() {
    cmd="$@"
    if [ $(id) -eq 0 ]
    then
        $cmd
    else
        sudo $cmd
    fi
}

function dnf_install() {
    maybe_sudo dnf install -y ansible git
}

function apt_install() {
    maybe_sudo apt update
    maybe_sudo apt install -y ansible git
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
}

main
