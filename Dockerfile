# SPDX-License-Identifier: GPL-3.0-only

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM rust:1.82-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake make git \
    && rm -rf /var/lib/apt/lists/*

RUN rustup component add clippy rustfmt && \
    cargo install cargo-tarpaulin cargo-audit cargo-deny cbindgen

WORKDIR /build
COPY Cargo.toml Cargo.lock* ./
COPY clippy.toml deny.toml cbindgen.toml ./
#adicionei os copy pedido 
COPY rust-toolchain.toml ./
COPY rust/ ./rust/
COPY build.rs ./



RUN cargo fetch
RUN mkdir -p include && cargo build --release



# ── Stage 2: Test + Coverage ──────────────────────────────────────────────────
FROM builder AS test

COPY test/ ./test/

RUN cargo test --all-features 2>&1 | tee /tmp/test-results.txt

RUN cargo tarpaulin \
    --out Lcov \
    --output-dir /coverage \
    --all-features \
    --exclude-files "rust/src/ffi.rs" 
    

# ── Stage 3: Final minimal runtime image ──────────────────────────────────────
FROM debian:bookworm-slim AS final

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/libmap2check.a /usr/local/lib/
COPY --from=builder /build/include/map2check.h /usr/local/include/
COPY --from=test /coverage /coverage

LABEL maintainer="herberthb12@gmail.com"
LABEL org.opencontainers.image.title="map2check-library"
LABEL org.opencontainers.image.description="Rust library to support Map2Check program verification tool"
LABEL org.opencontainers.image.licenses="GPL-3.0-only"
LABEL org.opencontainers.image.version="1.0.0"
