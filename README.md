# Android

Monorepo Windows natif : Bun 1.4.4, Rust nightly, Java et Android.

| Répertoire | Fonction |
|---|---|
| `crates/android-native` | Rust, ABI C et JNI, Windows et quatre ABI Android |
| `packages/android-web` | Bun, frontend et FFI vers Rust |
| `apps/java-ffi` | Java vers Rust par JNI |
| `apps/android` | APK Jetpack Compose/Material 3, Java/JNI, Rust et assets Bun |
| `apps/java-latest` | Compilation et exécution Java 27 |

Voir [START-HERE.md](START-HERE.md) pour les commandes et [PLAN.md](PLAN.md) pour les validations.

Les références officielles d'octobre 2026 sont dans [docs/android-october-2026.md](docs/android-october-2026.md). Les corpus par domaine et le script Bun de synchronisation sont pilotés depuis `docs/`.
