#!/bin/bash

# Ejecutar script desde esta carpeta

CYAN=$(tput setaf 6)
RESET=$(tput sgr0)
BOLD=$(tput bold)

function asksure() {
    echo "${BOLD}${CYAN}[$(date +'%F %T')]: $1 (Yy/Nn)${RESET}"
    while read -r answer; do
        if [[ $answer = [YyNn] ]]; then
            [[ $answer = [Yy] ]] && retval=0
            [[ $answer = [Nn] ]] && retval=1
            break
        fi
        echo "${BOLD}${CYAN}[$(date +'%F %T')]: $1 (Yy/Nn)${RESET}"
    done

    return ${retval}
}

function maquina_reverse_proxy() {
    if asksure "¿Desea hacer la configuración inicial de la máquina reverse_proxy?"; then
        ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${G10_REVERSE_PROXY}"
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_REVERSE_PROXY} 'bash -s' < ./setup-docker.sh
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_REVERSE_PROXY} 'bash -s' < ./setup-port-bending-reverse-proxy.sh
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_REVERSE_PROXY} 'bash -s' < ./setup-nfs-client.sh
    fi

    if asksure "¿Desea tranferir el docker-compose y las .env a la máquina reverse_proxy?"; then
        scp -i ../../secure/key_prod_rsa ../../../docker/docker-compose.prod.yml ubuntu@${G10_REVERSE_PROXY}:~/docker-compose.prod.yml
        scp -i ../../secure/key_prod_rsa ./run-reverse-proxy.sh ubuntu@${G10_REVERSE_PROXY}:~/run-reverse-proxy.sh
        scp -i ../../secure/key_prod_rsa ../../../docker/*.env ubuntu@${G10_REVERSE_PROXY}:~/
    fi

    if asksure "¿Desea entrar a la máquina para ejecutar ~/run-reverse-proxy.sh?"; then
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_REVERSE_PROXY}
    fi
}

function maquina_nfs() {
    if asksure "¿Desea hacer la configuración inicial de la máquina nfs?"; then
        ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${G10_NFS}"
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_NFS} 'bash -s' < ./setup-docker.sh
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_NFS} 'bash -s' < ./setup-nfs-server.sh
    fi

    if asksure "¿Desea tranferir el docker-compose y las .env a la máquina nfs?"; then
        scp -i ../../secure/key_prod_rsa ../../../docker/docker-compose.prod.yml ubuntu@${G10_NFS}:~/docker-compose.prod.yml
        scp -i ../../secure/key_prod_rsa ./run-nfs.sh ubuntu@${G10_NFS}:~/run-nfs.sh
        scp -i ../../secure/key_prod_rsa ../../../docker/*.env ubuntu@${G10_NFS}:~/
    fi

    if asksure "¿Desea entrar a la máquina para ejecutar ~/run-nfs.sh?"; then
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_NFS}
    fi
}

function maquina_jobs() {
    if asksure "¿Desea hacer la configuración inicial de la máquina jobs?"; then
        ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${G10_JOBS}"
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_JOBS} 'bash -s' < ./setup-docker.sh
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_JOBS} 'bash -s' < ./setup-nfs-client.sh
    fi

    if asksure "¿Desea tranferir el docker-compose y las .env a la máquina jobs?"; then
        scp -i ../../secure/key_prod_rsa ../../../docker/docker-compose.prod.yml ubuntu@${G10_JOBS}:~/docker-compose.prod.yml
        scp -i ../../secure/key_prod_rsa ./run-jobs.sh ubuntu@${G10_JOBS}:~/run-jobs.sh
        scp -i ../../secure/key_prod_rsa ../../../docker/*.env ubuntu@${G10_JOBS}:~/
    fi

    if asksure "¿Desea entrar a la máquina para ejecutar ~/run-jobs.sh?"; then
        ssh -i ../../secure/key_prod_rsa ubuntu@${G10_JOBS}
    fi
}

function main() {
    if [ -z "${G10_REVERSE_PROXY}" ] || [ -z "${G10_NFS}" ] || [ -z "${G10_JOBS}" ]; then
        echo "[$(date +'%F %T')]: No se ha encontrado una de las variable de entorno: G10_REVERSE_PROXY, G10_NFS ó G10_JOBS" 1>&2
        exit 1
    fi

    maquina_nfs
    maquina_jobs
    maquina_reverse_proxy
}

main