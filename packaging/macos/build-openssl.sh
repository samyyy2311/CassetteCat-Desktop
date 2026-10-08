#!/bin/sh
# Builds a universal (arm64 and x86_64) static OpenSSL for the macOS app from a pinned, checksummed release.
# Homebrew only provides the runner's own architecture. Usage: build-openssl.sh <install prefix>
set -eu

version=3.5.9
sha256=603f5602e2eef00d77fbd429d34dcd5822bb301757a1bc9cdb24c670f1eb859a
prefix="$1"
work="$(mktemp -d)"

curl -fsSL -o "$work/openssl.tar.gz" \
  "https://github.com/openssl/openssl/releases/download/openssl-$version/openssl-$version.tar.gz"
echo "$sha256  $work/openssl.tar.gz" | shasum -a 256 -c -

for arch in arm64 x86_64; do
  mkdir "$work/$arch"
  tar -xzf "$work/openssl.tar.gz" -C "$work/$arch" --strip-components 1
  (
    cd "$work/$arch"
    ./Configure "darwin64-$arch-cc" no-shared no-tests no-apps no-docs -mmacosx-version-min=12.0 \
      --prefix="$work/install-$arch" --libdir=lib
    make -j"$(sysctl -n hw.ncpu)" build_libs
    make install_dev
  )
done

mkdir -p "$prefix/lib"
cp -R "$work/install-arm64/include" "$prefix/"
for lib in libcrypto.a libssl.a; do
  lipo -create "$work/install-arm64/lib/$lib" "$work/install-x86_64/lib/$lib" -output "$prefix/lib/$lib"
done
