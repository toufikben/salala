/// The commit CI stamps into the APK with `--dart-define=SALALA_BUILD_TAG`.
///
/// Empty in a local run, which is the point: a device screenshot that shows a
/// SHA proves the build on the phone is the one CI published, not a stale file.
const String buildTag = String.fromEnvironment('SALALA_BUILD_TAG');

/// The version a breeder reads on the About page and in What's new.
///
/// Typed here rather than read off the platform because the only two places that
/// show it are text pages, and a plugin call to fetch a string the binary already
/// contains would be a channel round trip for nothing — plus a plugin to mock in
/// every test that opens About.
///
/// The cost of typing it is drift: `pubspec.yaml` is what the store reads, and a
/// second copy that nobody regenerates can say `0.1.0` three releases later.
/// `test/core/build_info_test.dart` reads the pubspec and fails when the two
/// disagree, so the drift is caught in the suite rather than by a buyer.
const String appVersion = '0.1.0';
