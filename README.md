# h20remind

Track how much water you drink, see your progress against a daily goal, and
get gentle hourly reminders. Runs on Android, iOS and the web, with data synced
through Firebase.

## Features

- **Today** – progress ring, one-tap quick add, custom amounts, swipe to delete
  with undo.
- **History** – seven-day chart, daily average, goal streak and a 30-day log.
- **Settings** – daily goal and hourly reminders (Android and iOS).
- Material 3 design with light and dark themes and adaptive layouts for phones,
  tablets and desktop browsers.

## Getting started

Requires Flutter 3.47 or newer.

```sh
flutter pub get
flutter run
```

Firebase requirements (one-time, in the Firebase console):

- **Authentication → Sign-in method → Google** must be enabled.
- Android: add the SHA-1 of your signing key to the Android app.
- Deploy the security rules with `firebase deploy --only firestore:rules`.

## Architecture

```
lib/
  core/          Theme, breakpoints, date and number helpers
  domain/        Models, repository interfaces, pure business logic
  data/          Firebase Auth, Firestore and local-notification implementations
  presentation/  Screens, widgets and ChangeNotifier controllers (provider)
```

- Presentation depends only on the interfaces in `domain/`. Concrete Firebase
  implementations are wired up in `main.dart`, so tests run against in-memory
  fakes.
- Data for a user is scoped by `UserScope`, which rebuilds all repositories and
  controllers when the signed-in account changes.
- History aggregation runs on a background isolate (`compute`) once a snapshot
  is large enough to risk dropping frames.
- The Firestore schema is unchanged from v1, so existing data keeps working.

## Checks

```sh
dart format lib test
flutter analyze
flutter test
```
