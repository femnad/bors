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
    maybe_sudo dnf install -y curl git python3-virtualenv
}

function apt_install() {
    maybe_sudo apt update
    maybe_sudo apt install -y curl git python3-virtualenv
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
    ansible-pull -U https://github.com/femnad/casastrap.git -i "$inventory" init-fup.yaml -e ansible_python_interpreter=/usr/bin/python3 --diff
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
    ${HOME}/bin/fup
}

function main() {
    install_packages
    venv_install_ansible
    ansible_pull
    fup
}

main
