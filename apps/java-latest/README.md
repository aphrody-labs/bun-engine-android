# Java latest

JDK Eclipse Temurin 27+35, dernière version feature publiée annoncée par l'API officielle Adoptium le 12 octobre 2026.

Le ZIP Windows x64 est installé dans `../tools/jdk-latest/` après vérification SHA256. La provenance est enregistrée dans `../tools/jdk-latest/release.json`.

`./verify.ps1` compile et exécute `HelloLatest.java` avec ce JDK directement. Aucune modification du PATH ou de JAVA_HOME : le JDK 21 utilisé par Android/Ghidra reste disponible séparément.
