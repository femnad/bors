#!/usr/bin/env bash
ALIASES_FILE="${HOME}/.bash_aliases"
VIMRC="${HOME}/.vimrc"

cat > "$ALIASES_FILE" << EOF
alias k=kubectl
alias kaf='kubectl apply -f'
alias kd='kubectl delete'
alias kds='kubectl describe'
alias kdsn='kubectl describe node'
alias kdp='kubectl delete pod'
alias kgdy='kubectl get deployment -o yaml'
alias kdsp='kubectl describe pod'
alias kgcm='kubectl get configmap'
alias kgcmy='kubectl get configmap -o yaml'
alias kgd='kubectl get deployment'
alias kg='kubectl get'
alias kgn='kubectl get nodes'
alias kgp='kubectl get pod'
alias kgpy='kubectl get pod -o yaml'
alias kgpan='kubectl get pod --all-namespaces'
alias kgs='kubectl get svc'
alias kgsa='kubectl get sa'
alias kgsay='kubectl get sa -o yaml'
alias kgsc='kubectl get secret'
alias kgscy='kubectl get secret -o yaml'
alias kl='kubectl label'
alias v=vim
EOF

cat > "$VIMRC" << EOF
set nocompatible
set hlsearch
set ignorecase
set incsearch
set number
syntax on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set nrformats-=octal
EOF

bash
