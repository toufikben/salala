import '../data/db/settings_dao.dart';

/// How long the free trial lasts, counted in whole days from the first launch.
const int kTrialDays = 15;

/// Whether this build is allowed to sell anything.
///
/// `false` for now, and it is the only switch that has to be flipped on the day
/// the app starts charging: every gate below reads it, so nothing that is free
/// today can become locked by a mistake somewhere else.
const bool kBillingEnabled = false;

/// The features that will be paid one day, named so the gate can be asked about
/// one of them rather than about "Pro".
///
/// An enum rather than a list of strings because the call sites have to be told
/// apart at compile time: a lock added to a feature that is not on this list is a
/// lock nobody can price, and a feature added here without a call site is a
/// promise the app does not keep.
enum ProFeature {
  /// Photos beyond the free allowance.
  unlimitedPhotos,

  /// The branded PDF pack a breeder hands to a buyer.
  reports,

  /// The sale contract and its printed terms.
  contracts,

  /// The kennel statistics page.
  ///
  /// A report over records she already has, not a record itself. The pedigree
  /// and the backup are deliberately *not* here: both are the breeder's own
  /// data, and the app promises on its seventh introduction card that her
  /// records leave the phone whenever she says so. A paywall on the only copy
  /// of a ledger is the one gate this app must never have.
  statistics,
}

/// Where the trial stands today.
class TrialState {
  const TrialState({required this.daysLeft, required this.expired});

  /// Whole days still included. Never negative: a screen that has to phrase a
  /// minus sign has already lost.
  final int daysLeft;

  final bool expired;

  /// True while the trial is still running. Not the same as "unlocked" — see
  /// [ProGate.allows].
  bool get inTrial => !expired;
}

/// Whether a paid feature answers, given the trial and whether Pro was bought.
///
/// Split from [TrialService] so the decision is a pure function and can be
/// tested on the day billing is switched on rather than after it. With
/// [billingEnabled] false everything is allowed, which is the whole of "the app
/// is free and the structure is dormant".
class ProGate {
  const ProGate({required this.billingEnabled, required this.proOwned});

  final bool billingEnabled;
  final bool proOwned;

  bool allows({required bool expired, required ProFeature feature}) {
    if (!billingEnabled) return true;
    if (proOwned) return true;
    if (!expired) return true;
    // The free tier is the ledger itself: animals, litters, doses, weights, the
    // basic CSV. Nothing in this list takes a record away — a breeder who never
    // pays keeps every dog she has entered, and loses only the extras.
    return !_paid.contains(feature);
  }

  static const Set<ProFeature> _paid = <ProFeature>{
    ProFeature.unlimitedPhotos,
    ProFeature.reports,
    ProFeature.contracts,
    ProFeature.statistics,
  };
}

/// The trial clock.
///
/// Stored in the settings table rather than in memory because a trial that
/// restarts with the process is not a trial. The keystore is deliberately not
/// used: a cleared keystore would look like a fresh install, and the settings
/// row travels with the ledger it belongs to.
class TrialService {
  TrialService({required this.settings, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The settings table the trial start lives in. Public because the named
  /// argument is the constructor's whole API, and a private field would force a
  /// duplicate parameter name for no gain.
  final SettingsDao settings;
  final DateTime Function() _clock;

  /// Reads the trial, starting it if this is the first launch.
  ///
  /// The start day is a calendar day, so time of day never moves the count: a
  /// breeder who installed at 23:50 gets the same fifteen days as one who
  /// installed at noon.
  Future<TrialState> state() async {
    final now = _clock();
    final startedMs =
        await settings.readInt(SettingKeys.trialStartedAt) ??
        await _start(now);
    final elapsed = _wholeDaysBetween(startedMs, now.millisecondsSinceEpoch);
    // A clock wound back before the install would make the elapsed count
    // negative, and arithmetic alone would read that as a longer trial than the
    // one that was granted. The floor is what stops a phone's calendar from
    // being a way to buy time.
    final spent = elapsed < 0 ? 0 : elapsed;
    final left = kTrialDays - spent;
    return TrialState(daysLeft: left < 0 ? 0 : left, expired: left <= 0);
  }

  /// Writes the start day and answers it, so `state` can go on in one read.
  Future<int> _start(DateTime now) async {
    final start = DateTime(now.year, now.month, now.day);
    final ms = start.millisecondsSinceEpoch;
    await settings.write(
      SettingKeys.trialStartedAt,
      '$ms',
      nowMs: now.millisecondsSinceEpoch,
    );
    return ms;
  }

  /// Whether one paid feature answers today.
  ///
  /// Every call site asks about a named feature rather than about "Pro", which is
  /// what keeps the sentence on the upgrade screen honest: it lists the features
  /// that are actually gated, not the ones someone remembered to list.
  Future<bool> unlocked(
    ProFeature feature, {
    bool proOwned = false,
  }) async {
    if (!kBillingEnabled) return true;
    final trial = await state();
    return ProGate(
      billingEnabled: kBillingEnabled,
      proOwned: proOwned,
    ).allows(expired: trial.expired, feature: feature);
  }
}

/// Whole calendar days from [fromMs] to [toMs], both read as days.
///
/// Rounded rather than truncated because of daylight saving: two days across a
/// spring-forward are 47 hours, and truncating would call that one day and give
/// the trial an extra morning.
int _wholeDaysBetween(int fromMs, int toMs) {
  final from = DateTime.fromMillisecondsSinceEpoch(fromMs);
  final to = DateTime.fromMillisecondsSinceEpoch(toMs);
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return (b.difference(a).inHours / 24).round();
}
