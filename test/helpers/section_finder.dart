import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/presentation/widgets/animal_timeline_card.dart';

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

/// The text as the *record sections* draw it — anywhere on the page except
/// inside the timeline card.
///
/// The card at the top of the animal's page is a second reading of rows the six
/// sections below already show, so every dose name, test panel, visit reason and
/// weigh-in is on the page twice. A test about the section — can this row be
/// corrected, does it disappear when it is deleted — has to say which of the two
/// copies it means, and the one it means is the section's own.
Finder sectionText(String text) => find.byElementPredicate((element) {
  final widget = element.widget;
  if (widget is! Text || widget.data != text) return false;
  return !_insideTimeline(element);
}, description: 'text "$text" outside the timeline');

/// [sectionText] for a substring, the way `find.textContaining` is for text.
Finder sectionTextContaining(String text) => find.byElementPredicate((element) {
  final widget = element.widget;
  if (widget is! Text) return false;
  final data = widget.data;
  if (data == null || !data.contains(text)) return false;
  return !_insideTimeline(element);
}, description: 'text containing "$text" outside the timeline');
