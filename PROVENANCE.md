# Provenance

This repository contains Aphrody Labs source code originally developed in
`C:\src\android`. The distributable source is MIT licensed.

Android SDK, NDK, JDK, Gradle distributions, reverse-engineering tools, device
images, signing material, application packages, caches and generated artifacts
are deliberately excluded. Their upstream licenses remain with their vendors.

Pinned third-party Rust dependencies are declared in `Cargo.lock`; Android and
Jetpack coordinates are declared in `apps/android/gradle/libs.versions.toml`.
The files under `docs/references` are metadata snapshots from Google Maven and
are retained as provenance, not vendored executable code.
