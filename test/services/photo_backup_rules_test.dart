import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salala/services/photo_files.dart';

/// D10's privacy promise is a sentence about a path, and a path in a comment is
/// not evidence. The first version of these rules read
/// `<exclude domain="file" path="photos" />`, which is `<home>/files/photos`.
/// The Realme then answered `run-as com.toufikben.ledger ls -lR
/// app_flutter/photos` with the pictures under `<home>/app_flutter/photos`:
/// path_provider's Android documents directory is a `getDir()` folder beside
/// `files/`, not inside it. The exclusion matched nothing while looking entirely
/// correct, which is the failure a privacy rule is most likely to have.
///
/// CI cannot ask path_provider where it writes, and `allowBackup="false"` means
/// a backup run on the phone refuses to produce the listing that would settle
/// it. What CI can do is refuse the split between the folder this app names and
/// the folder the rules name, because that is the half that drifted.
void main() {
  /// Read off the phone on 2026-10-11, not off a plugin README.
  const documentsDirOnAndroid = 'app_flutter';

  const expectedPhotoDir = '$documentsDirOnAndroid/$photosDirectoryName';

  /// Android's own domain-to-directory table, for the domains these two files
  /// use. A domain missing from it is a test failure rather than a silent pass.
  const domainDirs = <String, String>{
    'root': '',
    'file': 'files',
    'database': 'databases',
    'sharedpref': 'shared_prefs',
  };

  final excludePattern = RegExp(
    r'<exclude\s+domain="([^"]+)"\s+path="([^"]+)"\s*/>',
  );

  List<String> homeRelativeExcludes(String xml) =>
      excludePattern.allMatches(xml).map((match) {
        final domain = match.group[1]!;
        final dir = domainDirs[domain];
        expect(
          dir,
          isNotNull,
          reason:
              'domain "$domain" is not resolved here, so a rule that '
              'happens to name the right path could pass by accident',
        );
        return <String>[
          dir!,
          match.group[2]!,
        ].where((part) => part.isNotEmpty).join('/');
      }).toList();

  String sectionOf(String xml, String tag) {
    final start = xml.indexOf('<$tag>');
    expect(start, isNonNegative, reason: 'no <$tag> block');
    final end = xml.indexOf('</$tag>', start);
    expect(end, greaterThan(start), reason: '<$tag> is never closed');
    return xml.substring(start, end);
  }

  void expectPhotosExcluded(String label, String xml) {
    expect(
      homeRelativeExcludes(xml),
      contains(expectedPhotoDir),
      reason:
          '$label does not exclude $expectedPhotoDir, the folder the app '
          'actually writes pictures to',
    );
  }

  test('the Android 12+ rules exclude the folder the code writes to', () {
    final xml = File('android/app/src/main/res/xml/data_extraction_rules.xml')
        .readAsStringSync();
    expectPhotosExcluded('cloud-backup', sectionOf(xml, 'cloud-backup'));
    expectPhotosExcluded('device-transfer', sectionOf(xml, 'device-transfer'));
  });

  test('the legacy rules exclude the same folder', () {
    expectPhotosExcluded(
      'full-backup-content',
      File('android/app/src/main/res/xml/backup_rules.xml').readAsStringSync(),
    );
  });
}
