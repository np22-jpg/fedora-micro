#!/usr/bin/bash

remote_container=$1
local_container=$2

set -e

generate_rpm_list() {
    micromount=$1

    dnf list installed --installroot "$micromount"
}

microcontainer=$(buildah from "$remote_container") ||
    microcontainer=$(buildah from "quay.io/fedora/fedora")
micromount=$(buildah mount "$microcontainer")

# grabs VERSION_ID 
# shellcheck source=/dev/null
source "$micromount"/etc/os-release

echo Building on "$VERSION_ID"
generate_rpm_list "$micromount" >"current"
cat current

microcontainer=$(buildah from "$local_container")
micromount=$(buildah mount "$microcontainer")
generate_rpm_list "$micromount" >"update"
cat update

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

if [[ $TARGETARCH == arm64 ]]; then TARGETARCH=aarch64; fi