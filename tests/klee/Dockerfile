# SPDX-License-Identifier: GPL-3.0-only
#
# Image for tests/klee_paths.sh: Map2Check's development image (clang-16,
# LLVM 16 tools, KLEE 3.1, AFL++) plus rustup with the two toolchains the
# runtime needs: 1.82.0 (main build, the libFuzzer runtime of the cross
# test) and 1.72.1 (LLVM 16, the KLEE runtime, D1 route A'). Same recipe as
# the D1 spike's spikes/llvm16/Dockerfile.rust.
#
#   docker build -t map2check-dev:cutover-klee-rust tests/klee
FROM map2check-dev:cutover-f01e8c3e
USER root
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.82.0 --profile minimal \
 && rustup toolchain install 1.72.1 --profile minimal \
 && chmod -R a+rwX /opt/rustup /opt/cargo
USER map2check
