#!/usr/bin/bash

remote_container=$1
local_container=$2

set -e

podman run --name current "$remote_container" cat /etc/PACKAGES > "current" || echo "Packages not found!"
podman run --name update "$local_container" cat /etc/PACKAGES > "update" || echo "Packages not found!"


echo Generating Diff
diff current update > "diff" || true

cat diff

if [ -s diff ]; then
    echo Changes detected!
    exit 0
else
    echo No changes!
    exit 1
fi