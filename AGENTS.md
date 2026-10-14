# Android monorepo

Windows natif uniquement. Lire GOAL.md, PLAN.md et START-HERE.md avant modification.

Structure : `crates/` Rust nightly, `packages/` Bun 1.4.4, `apps/` Java/JNI et Android.
Le SDK, les outils et les sources RE externes ne sont pas des membres du workspace.

Utiliser `scripts/bun.ps1` pour garantir le runtime Bun 1.4.4 du checkout propriétaire, configurable via ANDROID_BUN_BIN ou APHRODY_BUN_CHECKOUT. Ne pas changer le checkout Bun pendant ce travail.
Build Cargo sérialisé : `scripts/build-rust.ps1`. Charger `scripts/env.ps1` pour SDK/JDK.
Ne pas enregistrer données personnelles, clés ADB, keystores ou autres secrets dans Git.
