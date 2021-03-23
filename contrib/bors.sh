#!/usr/bin/env bash
set -euo pipefail

BASE_VENV="$HOME/.venv"
ORIGINAL_PATH="$PATH"
SALT_HOME="${HOME}/.salt"
SALT_CONFIG="${SALT_HOME}/config"
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
    ansible-pull -U https://github.com/femnad/casastrap.git -i "$inventory" init-salt.yaml -e ansible_python_interpreter=/usr/bin/python3 --diff
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

function init_salt() {
    mkdir -p "${SALT_HOME}"
    mkdir -p "${SALT_CONFIG}"
    cat > "${SALT_HOME}/Saltfile" << EOF
salt-ssh:
  config_dir: ${SALT_CONFIG}
  ssh_log_file: ${SALT_HOME}/logs/ssh.log
  state_output: changes
  ssh_wipe: True
EOF

    current_user="$(whoami)"
    cat > "${SALT_CONFIG}/master" << EOF
pki_dir: /home/${current_user}/.salt/pki

cachedir: /home/${current_user}/.salt/cache

file_roots:
  base:
    - /home/${current_user}/z/fm/anr/state

pillar_roots:
  base:
    - /home/${current_user}/z/fm/anr/pillar

master_roots: /home/${current_user}/.salt/roots

osenv:
  driver: env

pillar_safe_render_error: False

github-lookup:
  driver: rest
  keys:
    url: https://api.github.com/users/{{user}}/keys
    backend: requests

gpg_keydir: /home/${current_user}/.gnupg
EOF

    cat > "${SALT_CONFIG}/roster" << EOF
self:
  host: localhost
  user: ${current_user}
  priv: agent-forwarding
  sudo: true
EOF
}

function salt_apply() {
    init_salt
    activate_venv salt
    pushd "$SALT_STATES"
    salt-ssh self state.apply || true
    salt-ssh sudo state.apply || true
    # Run again to account for dependency failage
    salt-ssh self state.apply || true
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
