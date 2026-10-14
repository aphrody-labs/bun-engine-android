# Android / Material / Compose — 12 octobre 2026

Recherche effectuée sur les sources officielles Android, Google Maven, Maven Central et les dépôts GitHub Google. Les versions ci-dessous sont des versions publiées, vérifiées le **12 octobre 2026**; la date du document ne change pas la version du BOM.

## Versions stables vérifiées

| Élément | Version | Source primaire locale |
|---|---|---|
| Android Gradle Plugin | 9.4.1 | `references/agp.xml` |
| Kotlin Gradle Plugin / compilateur Compose | 2.4.21 | `references/kotlin.xml` |
| Compose BOM | **2026.09.00** | `references/compose-bom.xml` |
| Runtime, UI, Foundation et Animation Compose | 1.12.1 | `references/bom-pom.pom` |
| Compose Material 3 | 1.4.0 | `references/material3.xml` |
| Material 3 Adaptive, Layout et Navigation | 1.3.0 | `references/bom-pom.pom` |
| Activity Compose | 1.13.0 | `references/activity.xml` |
| Lifecycle Runtime Compose | 2.11.0 | `references/lifecycle.xml` |
| Material Components Android, Views | 1.14.0 | `references/mdc-metadata.xml` |

Le BOM 2026.09.00 publie déjà les bibliothèques Compose 1.12.1, Material 3 1.4.0 et Adaptive 1.3.0. Les métadonnées publient aussi Runtime 1.13.0-beta01, Material 3 1.5.0-beta01 et Kotlin 2.5.0-Beta1 : ce sont des préversions. Sources : [Google Maven](https://dl.google.com/dl/android/maven2/androidx/compose/compose-bom/2026.09.00/compose-bom-2026.09.00.pom), [Kotlin Maven Central](https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/maven-metadata.xml).

## Configuration Android native

AGP 9 active Kotlin intégré. Dans le module Android, conserver `com.android.application`, appliquer `org.jetbrains.kotlin.plugin.compose`, activer `buildFeatures.compose` et aligner la version du plugin Compose sur celle du compilateur Kotlin effectivement résolu. Le BOM gère les versions des bibliothèques Compose, pas le compilateur. Les dépendances Activity et Lifecycle gardent leurs versions explicites. [Kotlin intégré](https://developer.android.com/build/migrate-to-built-in-kotlin), [compilateur Compose](https://developer.android.com/develop/ui/compose/setup-compose-dependencies-and-compiler), [BOM](https://developer.android.com/develop/ui/compose/bom).

La configuration est intégrée dans [`apps/android/gradle/libs.versions.toml`](../apps/android/gradle/libs.versions.toml) et appliquée par [`app/build.gradle`](../apps/android/app/build.gradle). Le catalogue fixe AGP 9.4.1, Kotlin/Compose Compiler 2.4.21, BOM 2026.09.00, Activity 1.13.0, Lifecycle 2.11.0 et Adaptive 1.3.0. Le module active Compose, les outils de prévisualisation en debug, les tests Compose et le verrouillage des dépendances. Il utilise compile SDK 37.2, target SDK 37, min SDK **24** imposé par WebKit 1.17.1 et NDK 30.0.16248370. La bibliothèque Rust reste compatible API 23.

La chaîne du monorepo sépare `apps/android` pour Kotlin/Java et l'APK, `crates/android-native` pour Rust/JNI/C ABI, `packages/android-web` pour le bundle Bun et `apps/java-ffi` pour JNI Java21 / FFM Java27. Bun 1.4.4 construit le JavaScript sur Windows; les bibliothèques Rust Android sont chargées par JNI. Aucun runtime Bun Android ARM64 n'est fourni par la release Aphrody publiée vérifiée.

L'application native contient une galerie Material 3, `GalleryViewModel`, la collecte lifecycle-aware, `NavigationSuiteScaffold`, un thème dynamique et un contenu Bun chargé par `WebViewAssetLoader`. Les fichiers sont dans [`app/src/main/kotlin`](../apps/android/app/src/main/kotlin/com/aphrody/android). Cette WebView est celle de l'application Compose; l'intégration Tauri Android n'est pas qualifiée.

## Règles applicables à l'interface

- L'état partagé d'un écran appartient à son ViewModel; les composants reçoivent l'état et les callbacks. Collecter les Flow avec `collectAsStateWithLifecycle`. Les états locaux restaurables utilisent `rememberSaveable`; les données durables restent dans leur couche de données. [État](https://developer.android.com/develop/ui/compose/state-hoisting), [restauration](https://developer.android.com/develop/ui/compose/state-saving).
- Déclencher les effets dans les API prévues : `LaunchedEffect` avec clés pertinentes, `DisposableEffect` pour une ressource à libérer et `rememberUpdatedState` pour un callback qui ne doit pas relancer l'effet. [Effets](https://developer.android.com/develop/ui/compose/side-effects).
- Utiliser `MaterialTheme.colorScheme`, sa typographie et ses formes; fournir un thème clair/sombre et des couleurs dynamiques sur Android 12+, avec une palette définie pour les versions antérieures. [Material 3](https://developer.android.com/develop/ui/compose/designsystems/material3).
- Adapter la navigation à la **fenêtre disponible** et à la posture, avec `NavigationSuiteScaffold` et `currentWindowAdaptiveInfo`. Préserver l'état lors du redimensionnement; tenir compte des insets et des écrans pliables. [Navigation adaptative](https://developer.android.com/develop/ui/compose/layouts/adaptive/build-adaptive-navigation).
- Préserver les cibles tactiles de 48 dp et les sémantiques natives. Décrire les icônes actives, laisser les décorations sans description, utiliser des chaînes localisées et vérifier les grandes tailles de police. Le dernier correctif Compose Samples du 6 octobre remplace des hauteurs fixes par des minima pour éviter les textes coupés. [Accessibilité](https://developer.android.com/develop/ui/compose/accessibility/api-defaults), [correctif officiel](https://github.com/android/compose-samples/commit/5a390e4a9d3c4e5b30e942041bde93582c4d9492).
- Donner des clés stables aux listes, éviter le calcul coûteux dans la composition, limiter les lectures d'état fréquentes et réserver `derivedStateOf` aux valeurs qui changent moins souvent que leur entrée. Mesurer les parcours critiques en build release; un Baseline Profile propre à l'application doit être validé par Macrobenchmark. [Performance](https://developer.android.com/develop/ui/compose/performance/bestpractices), [profils](https://developer.android.com/develop/ui/compose/performance/baseline-profiles).

## Références GitHub figées

| Dépôt officiel | Commit consulté | Date UTC | Usage |
|---|---|---|---|
| [android/compose-samples](https://github.com/android/compose-samples/tree/5a390e4a9d3c4e5b30e942041bde93582c4d9492) | `5a390e4a9d3c4e5b30e942041bde93582c4d9492` | 2026-10-06 | Jetchat : état/thème; Reply : adaptation; Jetcaster : Flow/lifecycle |
| [android/nowinandroid](https://github.com/android/nowinandroid/tree/a49ed253d75e61a2b6ab80a8da677b57437b08eb) | `a49ed253d75e61a2b6ab80a8da677b57437b08eb` | 2026-09-22 | Architecture réactive, couches UI/données, tests et modularisation |
| [androidx/androidx](https://github.com/androidx/androidx/tree/034d37ae95b7db8560e520c0366696af56a37b96/compose) | `034d37ae95b7db8560e520c0366696af56a37b96` | 2026-10-12 | Source Compose; branche de développement, distincte des artefacts stables |
| [material-components-android](https://github.com/material-components/material-components-android/tree/60ff09436d5d477a4b9d02940f31eb01e1250620) | `60ff09436d5d477a4b9d02940f31eb01e1250620` | 2026-09-14 | Statut officiel de Material Views |

Material Components Views est en maintenance depuis l'annonce Compose-first de 2026. Le dépôt recommande Compose pour les nouvelles fonctionnalités Material et Android. [Guide officiel figé](https://github.com/material-components/material-components-android/blob/60ff09436d5d477a4b9d02940f31eb01e1250620/docs/getting-started.md).

## Preuve Context7 et limites

Les requêtes `context7_resolve_library_id` et `context7_query_docs` ont été exécutées via **aphrody-mcp**. Index consultés : `/websites/developer_android_develop_ui_compose` (rafraîchi le 2 octobre), `/android/compose-samples` (23 septembre); l'index source AndroidX annoncé était rafraîchi le 10 octobre. Setup/BOM, état/lifecycle, performance et Material/accessibilité ont retourné des extraits avec leurs URL officielles.

Les requêtes supplémentaires adaptive et source AndroidX ont atteint le quota mensuel Context7. Ces points ont été vérifiés directement dans les sources primaires Google/GitHub, sans considérer une erreur de quota comme une validation. L'exemple Kotlin 2.4.10 de Context7 est antérieur au dernier stable 2.4.21 vérifié sur Maven Central. Cette recherche documente les contrats; l'exécution de l'APK et les tests instrumentés constituent des validations séparées.

Les métadonnées XML/POM téléchargées et la provenance des requêtes sont dans [`references/`](references/android-october-2026.json).
