import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/agenda.dart';
import '../../data/models/vaccination.dart';
import 'app_providers.dart';

/// Every dose the herd is waiting for inside the agenda window, due date first.
///
/// The raw rows rather than the finished list, because the agenda also needs the
/// animals to put a name on each row: a provider that watched `animalsProvider`
/// would rebuild the whole agenda whenever any animal's details were edited, and
/// would tie the home screen's two reads into one. So the screen watches both and
/// folds them with `buildHerdAgenda` in its own build.
///
/// This is also D27: the query has to start while the screen is building, not
/// when the lazy list finally gets round to painting the agenda block, or the
/// read lands in the middle of whatever a test or a finger is already doing.
final agendaDosesProvider = FutureProvider.autoDispose<List<Vaccination>>((
  ref,
) {
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  return ref.read(daosProvider).vaccinations.dueBefore(agendaHorizonMs(nowMs));
});
