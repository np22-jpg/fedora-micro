FROM build AS cross

# Build glibc
WORKDIR /usr/src/glibc/{{ arch }}
RUN --mount=type=cache,target=/root/.cache/ccache \
    ../configure --build="$(../config.guess)" \
    --host={{ arch }}-linux-gnu \
    --with-headers=/usr/arm64-linux-gnu/include/ \
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
        --disable-werror \
        --target {{ arch }}-linux-gnu \
        --prefix=/usr/local && \
    make -j16 && \
    make install

# Build gcc
WORKDIR /usr/src/gcc/{{ arch }}
RUN --mount=type=cache,target=/root/.cache/ccache \
    ../configure \
        --build="$(../config.guess)" \
        --disable-nls \
        --disable-werror \
        --target aarch64-linux-gnu \
        --enable-threads=single \
        --enable-languages=c,c++ \
        --without-headers \
        --enable-multilib \
        --prefix=/usr/local && \
    make -j16 && \
    make install