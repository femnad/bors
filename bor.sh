#!/usr/bin/env bash
set -euEo pipefail

function bor() {
    root_dir=$(dirname $(realpath $0))
    pushd "${root_dir}"
    terraform apply -auto-approve
    ansible-playbook bors.yml
    popd
    terraform destroy -auto-approve
}

bor $@
