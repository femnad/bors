#!/usr/bin/env bash
set -euo pipefail

BASE_VENV="$HOME/.local/share/venv"
CHEZMOI_VERSION=2.16.0
ORIGINAL_PATH="$PATH"

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
    maybe_sudo dnf update -y
    maybe_sudo dnf install -y curl git python3-virtualenv
}

function apt_install() {
    maybe_sudo apt update
    maybe_sudo apt autoremove -y
    maybe_sudo apt upgrade -y
    maybe_sudo apt install -y curl git python3-virtualenv
}

function activate_venv() {
    venv="$1"

    source "${BASE_VENV}/${venv}/bin/activate"
}

function deactivate_venv() {
    deactivate
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
    ansible-pull -U https://github.com/femnad/casastrap.git -i "$inventory" init-fup.yml -e ansible_python_interpreter=/usr/bin/python3 --diff
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

function maybe_download_chezmoi() {
    if [ -f "${HOME}/bin/chezmoi" ]
    then
        return
    fi

    tempdir=$(mktemp -d)
    pushd $tempdir
    curl -L "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz" -OJ
    tar xf "chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz"
    popd
    mkdir -p "${HOME}/bin"
    mv "${tempdir}/chezmoi" "${HOME}/bin/chezmoi"
    rm -r "$tempdir"
}

function init_chezmoi() {
    maybe_download_chezmoi

    "${HOME}/bin/chezmoi" init https://gitlab.com/femnad/chezmoi.git
    "${HOME}/bin/chezmoi" apply
}


function fup() {
    activate_venv "pyinfra"

    "${HOME}/bin/chezmoi" apply
    pushd "${HOME}/z/fm/fup"
    "${BASE_VENV}/pyinfra/bin/pyinfra" @local main.py
    popd > /dev/null

    deactivate
}

function main() {
    install_packages
    init_chezmoi
    venv_install_ansible
    ansible_pull
    fup
}

main
