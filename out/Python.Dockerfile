# Based on https://catalog.redhat.com/software/containers/ubi8-micro/601a84aadd19c7786c47c8ea?container-tabs
# Also see https://github.com/AlmaLinux/docker-images/blob/master/dockerfiles/alma9/Dockerfile.micro
# Cross-building does not work because there are no development libraries for anything else. I'll have to do compile gcc from source.
# curl https://sourceware.org/pub/gcc/snapshots/LATEST-13/gcc-13-20230326.tar.xz | tar -xJ && cd gcc* && mkdir x86_64 && cd x86_64 && ../configure --target x86_86-linux-gnu && make -j16
# create seperate build directories from within the source tree per-arch

ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM registry.fedoraproject.org/fedora AS python-build 
ARG TARGETARCH

RUN --mount=type=cache,target=/var/cache/dnf --mount=type=cache,target=/root/.cache/ccache \
    if [[ $TARGETARCH == arm64 ]]; then TARGETARCH=aarch64-linux-gnu && CC="aarch64-linux-gnu-gcc" && CXX="aarch64-linux-gnu-g++"; fi && \
    if [[ $TARGETARCH == amd64 ]]; then TARGETARCH=x86_64-linux-gnu && CC=x86_64-linux-gnu-gcc && CXX=x86_64-linux-gnu-g++; fi && \
    if [[ $TARGETARCH == ppc64le ]]; then TARGETARCH=powerpc64le-linux-gnu && CC=powerpc64le-linux-gnu-gcc && CXX=powerpc64le-linux-gnu-g++; fi && \
    if [[ $TARGETARCH == s390x ]]; then TARGETARCH=s390x-linux-gnu && CC=s390x-linux-gnu-gcc && CXX=s390x-linux-gnu-g++; fi && \
    dnf install --nodocs -y --setopt install_weak_deps=false --setopt keepcache=true \
    autoconf bluez-libs-devel bzip2 bzip2-devel desktop-file-utils \
    expat-devel findutils gcc-c++ gdb gdbm-devel git-core \
    glibc-all-langpacks glibc-devel gmp-devel gnupg2 libGL-devel \
    libX11-devel libappstream-glib libb2-devel libffi-devel \
    libnsl2-devel libtirpc-devel libuuid-devel make mpdecimal-devel \
    ncurses-devel openssl-devel pkgconfig python-pip-wheel \
    python-setuptools-wheel python3-rpm-generators python3.11 \
    readline-devel rsync sqlite-devel tar tcl-devel tix-devel tk-devel \
    tzdata valgrind-devel xz xz-devel zlib-devel ccache binutils \
    gcc-x86_64-linux-gnu gcc-aarch64-linux-gnu gcc-powerpc64le-linux-gnu gcc-s390x-linux-gnu \
    gcc-c++-x86_64-linux-gnu gcc-c++-aarch64-linux-gnu gcc-c++-powerpc64le-linux-gnu gcc-c++-s390x-linux-gnu \
    binutils-x86_64-linux-gnu binutils-aarch64-linux-gnu binutils-powerpc64le-linux-gnu binutils-s390x-linux-gnu && \
    curl -f https://www.python.org/ftp/python/3.11.2/Python-3.11.2.tar.xz | \
    tar -xJC /usr/src/python --strip-components=1
WORKDIR /usr/src/python/base
RUN ../configure \
        --build="$(../config.guess)" \
        --host="$(../config.guess)" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		--with-lto \
		--with-system-expat \
		--without-ensurepip \
        --without-static-libpython && \
    LDFLAGS="-s -w" make -j$(nproc) && \
    make install

# https://github.com/python/cpython/issues/100535

WORKDIR /usr/src/python/out
RUN ../configure \
        --build="$(../config.guess)" \
        --host="aarch64-linux-gnu" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		--with-lto \
		--with-system-expat \
		--without-ensurepip \
        --with-build-python \
        --with-libc="/usr/local/aarch64-linux-gnu" \
        --prefix="/cross-python" \
        --exec-prefix="/cross-python" && \
    LDFLAGS="-s -w" make -j$(nproc) && \
    make install && \
    rsync -vr \
        --exclude *.pyc \
        --exclude *.pyo \
        --exclude test \
        --exclude tests \
        --exclude idle_test \
        --exclude libpython*a \
        /cross-python /python

FROM quay.io/np22-jpg/fedora-micro AS fedora-micro
COPY --from=python-build /python /usr
LABEL maintainer="np22-jpg"

LABEL name="np22-jpg/fedora-python3"

#labels for container catalog
LABEL summary="Fedora python3 micro image"
LABEL description="Very small image which doesn't install the package manager."
LABEL io.k8s.display-name="fedora-python3"

CMD /usr/local/bin/python3

# Mar 21, 2023
# stripped: 51.9MB on-disk, 18.27 compressed
# unstripped: 80.5MB on-disk, 30.04 compressed