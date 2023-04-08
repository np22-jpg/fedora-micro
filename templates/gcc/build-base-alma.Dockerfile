# First, download all needed dependencies, including arches to compile
# This allows us to compile glibc for the target arch, which is necessary to compile everything else

ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM {{ builder_image }} AS build 

# Install Packages

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install 'dnf-command(config-manager)' -y && \
    dnf config-manager --set-enabled crb -y && \
    dnf install -y epel-release && \
    dnf install --nodocs -y --setopt install_weak_deps=false --setopt keepcache=true \
    texinfo \
    bison \
    flex \
    gmp-devel \
    mpfr-devel \
    libmpc-devel \
    gcc \
    gcc-c++ \
    gdb \
    findutils \
    gettext \
    zlib-devel \
    jansson-devel \
    git-core \
    diffutils \
    gcc-{{ arch }}-linux-gnu \
    binutils-{{ arch }}-linux-gnu \
    kernel-cross-headers \
    ccache \
    git-core


FROM build AS cross
# Get sources
WORKDIR /usr/src
RUN git clone --depth=1 -b glibc-2.37 https://sourceware.org/git/glibc.git glibc && \
    git clone --depth=1 -b binutils-2_40 git://sourceware.org/git/binutils-gdb.git binutils && \
    git clone --depth=1 -b trunk https://gcc.gnu.org/git/gcc.git gcc

# Build glibc
WORKDIR /usr/src/glibc/{{ arch }}
RUN --mount=type=cache,target=/root/.cache/ccache \
    ../configure \
    --build="$(../config.guess)" \
    --prefix=/usr/local/ && \
    make -j16 && \
    make install prefix=/usr/local

# Build binutils
WORKDIR /usr/src/binutils/{{ arch }}
RUN --mount=type=cache,target=/root/.cache/ccache \
    ../configure \
        --build="$(../config.guess)" \
        --with-sysroot \
        --disable-nls \
        --disable-werror && \
    make -j16 && \
    make install prefix=/usr/local

# Build gcc
WORKDIR /usr/src/gcc/{{ arch }}
RUN --mount=type=cache,target=/root/.cache/ccache \
    ../configure \
        --build="$(../config.guess)" \
        --disable-nls \
        --disable-werror \
        --enable-threads=single \
        --enable-languages=c,c++ \
        --without-headers \
        --enable-multilib && \
    make -j16 && \
    make install