# Base foundation for the runtime.
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS foundation
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf update -y \ 
    && dnf install -y wget tar gzip glibc
WORKDIR /app


# Lambda foundation for the runtime.
FROM foundation AS foundation-lambda
ADD lambda-entrypoint.sh /lambda-entrypoint.sh
RUN wget https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-x86_64 \
    && mv aws-lambda-rie-x86_64 /usr/local/bin/aws-lambda-rie \
    && chmod +x /usr/local/bin/aws-lambda-rie
ENV LANG=en_US.UTF-8
ENV TZ=:/etc/localtime
ENV PATH=/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin
ENV LD_LIBRARY_PATH=/var/lang/lib:/lib64:/usr/lib64:/var/runtime:/var/runtime/lib:/var/task:/var/task/lib:/opt/lib
ENV LAMBDA_TASK_ROOT=/var/task
ENV LAMBDA_RUNTIME_DIR=/var/runtime
WORKDIR /var/task
ENTRYPOINT ["/lambda-entrypoint.sh"]


# Custom Rust image - only for building.
FROM foundation AS tasty-crab
# install rustup.rs
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="$PATH:/root/.cargo/bin"
RUN cargo --version
# install cargo-binstall
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
# install dependencies with it
RUN --mount=type=cache,target=/usr/local/cargo \
    --mount=type=cache,target=/app/target \
    cargo binstall -y cargo-chef cargo-nextest cargo-deny


# The buildkit -- built on top of tasty-crab layer.
FROM tasty-crab AS buildkit
ADD .docker /tmp
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf update -y \
    && dnf groupinstall -y "Development Tools" \ 
    && dnf install -y \
    zip \
    nasm \
    python3-pip \
    cmake3 \
    clang-devel \
    wget \
    curl-minimal \
    glibc \
    pkgconfig \
    lld \
    && dnf clean all
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install meson ninja cargo-lambda \
    && if ! [[ -f /usr/bin/cmake ]]; then ln -s /usr/bin/cmake3 /usr/bin/cmake; fi

