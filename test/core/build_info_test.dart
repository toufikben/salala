import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/build_info.dart';

/// Two copies of the version, and the file that keeps them agreeing.
///
/// `pubspec.yaml` is what the phone's package manager and the store read;
/// `appVersion` is what the About page paints. The About page cannot read the
/// pubspec at runtime — it is not bundled — so the constant is typed by hand, and
/// a hand-typed version is a version that says 0.1.0 three releases after it
/// stopped being true. This is the check that notices.
void main() {
  test('the version on the About page is the version in the pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final line = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(line, isNotNull, reason: 'pubspec.yaml has no version line');

    // `0.1.0+1` — the build number after the + is the store's, not the reader's.
    final declared = line!.group(1)!.split('+').first;
    expect(
      appVersion,
      declared,
      reason:
          'lib/core/build_info.dart says $appVersion and pubspec.yaml says '
          '$declared, so the About page is telling the breeder about a build '
          'that is not the one on their phone',
    );
  });
}
