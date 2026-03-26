# Chess Swiss Tournament App

A tournament management app for Android for Swiss tournaments in chess.

## Getting Started

This project is a Flutter application written in Dart.

- Run `flutter run` to run the app.
- To regenerate bindings after changing Java code, run
  `dart run tool/jnigen.dart`. This requires at least one APK build to have
  been run before, so that  JNIgen can obtain classpaths of Android Gradle
  libraries. Therefore, run `flutter build apk` once before generating bindings
  for the first time, or after a `flutter clean`.
- To generate the app build timestamp, run `dart run build_runner build --delete-conflicting-outputs`
- To run in release mode: `flutter run --release`

### TODOs:

- Welcome Dialog
- Mehr Snackbars (Player created etc.)
