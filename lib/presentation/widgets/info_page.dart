import 'package:flutter/material.dart';

/// One heading and the paragraph under it.
///
/// The prose pages — privacy, terms, what's new — differ only in their words, so
/// they differ only in data. A separate widget per page would be four copies of
/// the same `Text` with a `fontWeight` on it, and the fifth page would be the one
/// where the spacing drifted.
class InfoSection {
  const InfoSection(this.heading, this.body);

  final String heading;
  final String body;
}

/// A page that is read rather than operated: a title, sections, and whatever
/// rows the caller needs underneath them.
///
/// Deliberately not a `SelectableText` page: a breeder scanning for one answer on
/// a phone wants a heading they can find, and the licensing text a lawyer needs is
/// behind `showLicensePage`, which is searchable and copyable.
class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    this.sections = const <InfoSection>[],
    this.bullets = const <String>[],
    this.extra = const <Widget>[],
  });

  final String title;
  final List<InfoSection> sections;

  /// One line each, marked with a dot: the shape a "what's new" page wants, where
  /// every line is a separate fact and none of them has a heading.
  final List<String> bullets;

  /// Rows that are not prose: a version line, a licence button.
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: <Widget>[
          for (final section in sections) ...<Widget>[
            Text(
              section.heading,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 22),
          ],
          for (final line in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10, left: 2),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ...extra,
        ],
      ),
    );
  }
}
