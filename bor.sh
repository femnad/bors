#!/usr/bin/env bash
set -euEo pipefail

function bor() {
    root_dir=$(dirname $(realpath $0))
    pushd "${root_dir}"

    if ! [ -d .terraform/ ]
    then
        make
    fi

    terraform apply -auto-approve
    ansible-playbook bors.yml

    read -p 'Ready when you are '
    terraform destroy -auto-approve

    popd
}

bor $@
