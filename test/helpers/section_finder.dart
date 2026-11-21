import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/presentation/widgets/animal_timeline_card.dart';

/// Whether [element] sits inside the timeline card at the top of the ledger.
bool _insideTimeline(Element element) {
  var inside = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is AnimalTimelineCard) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

/// The string a widget draws, or null when it draws something else.
///
/// `Text` and `EditableText` and nothing else: those are the two kinds
/// `find.text` answers, and a scoped copy of it has to answer exactly the same
/// set. A `RichText` is *not* in that set — every `Text` builds one, so matching
/// it would answer twice for one string and every `tap` on the result would
/// throw. A form field is in it, which is what lets "the field still holds the
/// old value" be asserted once the assertion is scoped.
String? _drawnText(Widget widget) => switch (widget) {
  Text(:final data) => data,
  EditableText(:final controller) => controller.text,
  _ => null,
};

/// The text as the *record sections* draw it — anywhere on the page except
/// inside the timeline card.
///
/// The card at the top of the animal's page is a second reading of rows the six
/// sections below already show, so every dose name, test panel, visit reason and
/// weigh-in is on the page twice. A test about the section — can this row be
/// corrected, does it disappear when it is deleted — has to say which of the two
/// copies it means, and the one it means is the section's own.
Finder sectionText(String text) => find.byElementPredicate((element) {
  if (_drawnText(element.widget) != text) return false;
  return !_insideTimeline(element);
}, description: 'text "$text" outside the timeline');

/// [sectionText] for a substring, the way `find.textContaining` is for text.
Finder sectionTextContaining(String text) => find.byElementPredicate((element) {
  final drawn = _drawnText(element.widget);
  if (drawn == null || !drawn.contains(text)) return false;
  return !_insideTimeline(element);
}, description: 'text containing "$text" outside the timeline');
