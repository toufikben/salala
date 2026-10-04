/// The commit CI stamps into the APK with `--dart-define=SALALA_BUILD_TAG`.
///
/// Empty in a local run, which is the point: a device screenshot that shows a
/// SHA proves the build on the phone is the one CI published, not a stale file.
const String buildTag = String.fromEnvironment('SALALA_BUILD_TAG');
