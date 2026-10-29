---
name: swift-linux-toolchain
description: Install a working Swift 6 toolchain (swiftc, swift build/run/test, SwiftPM, Foundation) in a Linux cloud session when this package needs to be built or tested.
---

# Swift toolchain on the Linux workspace

Cloud sessions run Ubuntu 24.04 (x86_64) with no Swift installed. download.swift.org and GitHub release assets are blocked by the network allowlist, but archive.ubuntu.com works. Ubuntu 25.10 (questing) ships Swift 6.0.3 as a .deb. Extracting it, plus a few newer libraries that 24.04 lacks, into `/opt/swift` works without touching the system's packages.

Skip everything if `command -v swift` already succeeds, or if `/opt/swift` exists (then just source the env file).

## Install

Takes about 2 minutes and 2.2 GB on disk. Run as one Bash call with a long timeout (600000 ms):

```bash
set -e
D=$(mktemp -d)
cd "$D"
B=https://archive.ubuntu.com/ubuntu/
for f in \
  pool/universe/s/swiftlang/swiftlang_6.0.3-2build1_amd64.deb \
  pool/universe/s/swiftlang/libswiftlang_6.0.3-2build1_amd64.deb \
  pool/main/libx/libxml2/libxml2-16_2.14.5+dfsg-0.2_amd64.deb \
  pool/main/p/python3.13/libpython3.13_3.13.7-1_amd64.deb \
  pool/main/i/icu/libicu76_76.1-4ubuntu2_amd64.deb; do
  curl -fsS -m 300 -O "$B$f"
done
mkdir -p /opt/swift
for d in *.deb; do dpkg-deb -x "$d" /opt/swift; done
cat > /etc/profile.d/swift.sh <<'E'
export PATH=/opt/swift/usr/libexec/swift/bin:$PATH
export LD_LIBRARY_PATH=/opt/swift/usr/lib/x86_64-linux-gnu:/opt/swift/usr/lib/swift/linux${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
E
rm -rf "$D"
. /etc/profile.d/swift.sh
swift --version
```

If a download returns 404, the package version in the archive has moved. Fetch `https://archive.ubuntu.com/ubuntu/dists/questing/{main,universe}/binary-amd64/Packages.gz`, look up the current `Filename:` for each package above, and retry with those paths.

## Using it

Each Bash call starts a fresh shell, so prefix Swift commands with `. /etc/profile.d/swift.sh && `. The env file sets `PATH` and `LD_LIBRARY_PATH`.

```bash
. /etc/profile.d/swift.sh && swift build
. /etc/profile.d/swift.sh && swift test
```

A cold `swift build` of this package takes about 4.5 minutes on 2 CPUs, so give it a 600000 ms timeout. Incremental builds are fast.

## Limits

- Linux Swift only: no SwiftUI, UIKit, Combine, or Xcode projects.
- SwiftPM dependencies from GitHub resolve normally, since git over HTTPS works.
- `swift-format` is included, so the formatting step in `AGENTS.md` works too.
