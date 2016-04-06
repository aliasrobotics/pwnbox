#!/usr/bin/env bash

# Run superkojiman/pwnbox container in docker. 
# Store your .gdbinit, .radare2rc, .vimrc, etc in a ./rc directory. The contents will be copied to
# /root/ in the container.

ESC="\e["
RESET=$ESC"39m"
RED=$ESC"31m"
GREEN=$ESC"32m"
BLUE=$ESC"34m"

if [[ -z ${1} ]]; then
    echo -e "${RED}Missing argument CTF name.${RESET}"
    exit 0
fi

ctf_name=${1}

# set default docker-machine env ctf if available
if [[ ! -z `which docker-machine` ]]; then
    docker-machine env ctf > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        eval `docker-machine env ctf`
    fi
else
    echo "Could not find docker-machine ctf"
    exit 0
fi

# Create docker container and run in the background
docker run -it \
    -d \
    -h ${ctf_name}-ctf \
    --security-opt seccomp:unconfined \
    --name ${ctf_name}-ctf \
    superkojiman/pwnbox

# Tar config files in rc and extract it into the container
if [[ -d rc ]]; then
    cd rc
    if [[ -f rc.tar ]]; then
        rm -f rc.tar
    fi
    for i in .* *; do
        if [[ ! ${i} == "." && ! ${i} == ".." ]]; then
            tar rf rc.tar ${i}
        fi
    done
    cd - > /dev/null 2>&1
    cat rc/rc.tar | docker cp - ${ctf_name}-ctf:/root/
else
    echo -e "${RED}No rc directory found. Nothing to copy to container.${RESET}"
fi

# Create stop/rm script for container
cat << EOF > ${ctf_name}-stop.sh
#!/bin/bash
docker stop ${ctf_name}-ctf
docker rm ${ctf_name}-ctf
rm -f ${ctf_name}-stop.sh
EOF
chmod 755 ${ctf_name}-stop.sh

# Create a workdir for this CTF
docker exec ${ctf_name}-ctf mkdir /root/work

# Get a shell
echo -e "${GREEN}Let's pwn stuff!${RESET}"
docker attach ${ctf_name}-ctf
