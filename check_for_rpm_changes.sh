#!/usr/bin/bash

remote_container=$1
local_container=$2

set -e

generate_rpm_list() {
    micromount=$1
    VERSION_ID=$2

    dnf install \
        --installroot "$micromount" \
        --releasever "$VERSION_ID" \
        --setopt install_weak_deps=false \
        --nogpgcheck \
        --nodocs -y -q \
        rpm >/dev/null;

    chroot "$micromount" rpm -qa
}

microcontainer=$(buildah from "$remote_container") ||
    microcontainer=$(buildah from "quay.io/fedora/fedora")
micromount=$(buildah mount "$microcontainer")

# grabs VERSION_ID 
# shellcheck source=/dev/null
source "$micromount"/etc/os-release

echo Building on "$VERSION_ID"
generate_rpm_list "$micromount" "$VERSION_ID" >"current"
cat current

echo 
microcontainer=$(buildah from "$local_container")
micromount=$(buildah mount "$microcontainer")
generate_rpm_list "$micromount" "$VERSION_ID" >"update"
cat update

echo Generating Diff
# git diff -U0 current update | grep '^[+-]' | grep -Ev '^(--- a/|\+\+\+ b/)' >"diff" || true
diff current update

cat diff

if [ -s diff ]; then
    echo Changes detected!
    exit 0
else
    echo No changes!
    exit 1
fi
