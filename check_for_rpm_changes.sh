#!/usr/bin/bash

remote_container=$1
Containerfile=$2

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
        rpm >/dev/null

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

buildah bud -t update_image:test -f "$Containerfile" --build-arg VERSION_ID="$VERSION_ID" --cap-add SYS_CHROOT .
microcontainer=$(buildah from update_image:test)
micromount=$(buildah mount "$microcontainer")
generate_rpm_list "$micromount" "$VERSION_ID" >"update"

git diff -U0 current update | grep '^[+-]' | grep -Ev '^(--- a/|\+\+\+ b/)' >"diff"

cat diff

if [ -s diff ]; then
    echo Changes detected!
    exit 0
else
    echo No changes!
    exit 1
fi
