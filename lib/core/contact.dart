/// The two addresses this app ever names.
///
/// Neither is reached by code: the support address is shown as text the breeder
/// can copy, and the store listing is opened through the platform's own review
/// plugin. That is the whole contact surface of an app with no server — worth
/// having in one file so a release check can find both in a single look.
class SalalaContact {
  SalalaContact._();

  /// Written into the Help page and nothing else.
  ///
  /// A real inbox, not a form: a breeder with a dead phone and a question should
  /// not also need a working app to ask it.
  static const String supportEmail = 'support@salala.app';

  /// The Android package, which is what a store listing URL is built from.
  static const String androidPackage = 'com.toufikben.ledger';

  /// The iTunes numeric id is empty because iOS is deferred; `openStoreListing`
  /// reads it only on Apple's platforms, and a blank value there is the plugin's
  /// own "no listing configured" rather than a wrong link.
  static const String appStoreId = '';
}
