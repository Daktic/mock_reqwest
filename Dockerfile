ARG RUST_VERSION=1.72.0
ARG APP_NAME=mock_reqwest


################################################################################
# xx is a helper for cross-compilation.
# See https://github.com/tonistiigi/xx/ for more information.
FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.3.0 AS xx

################################################################################
# Create a stage for building the application.
FROM --platform=$BUILDPLATFORM rust:${RUST_VERSION}-alpine AS build
ARG APP_NAME
WORKDIR /app


# Copy cross compilation utilities from the xx stage.
COPY --from=xx / /

# Install host build dependencies.
RUN apk add --no-cache clang lld musl-dev git file


# This is the architecture you’re building for, which is passed in by the builder.
# Placing it here allows the previous steps to be cached across architectures.
ARG TARGETPLATFORM


# Install cross compilation build dependencies.
RUN xx-apk add --no-cache musl-dev gcc pkgconfig openssl-dev

ENV OPENSSL_DIR=/usr

RUN --mount=type=bind,source=src,target=src \
    --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
    --mount=type=bind,source=Cargo.lock,target=Cargo.lock \
    --mount=type=cache,target=/app/target/,id=rust-cache-${APP_NAME}-${TARGETPLATFORM} \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    set -e && \
    xx-cargo build --locked --release --target-dir ./target --target x86_64-unknown-linux-musl && \
    cp ./target/x86_64-unknown-linux-musl/release/$APP_NAME /bin/server && \
    xx-verify /bin/server


FROM alpine:3.18 AS final
#RUN apk add --no-cache alpine-sdk openssl-dev
#COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/


# Copy the executable from the "build" stage.
COPY --from=build /bin/server /bin/

# Expose the port that the application listens on.
EXPOSE 8080

# Add a Prod var
ENV STAGE=PROD

# What the container should run when it is started.
CMD ["/bin/server"]