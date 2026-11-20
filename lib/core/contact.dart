/// The two addresses this app ever names.
///
/// Neither is reached by code: the support address is shown as text the breeder
/// can copy, and the store listing is opened through the platform's own review
/// plugin. That is the whole contact surface of an app with no server — worth
/// having in one file so a release check can find both in a single look.
class AppContact {
  AppContact._();

  /// Written into the Help page and nothing else, and read by the store listing.
  ///
  /// A real inbox, not a form: a breeder with a dead phone and a question should
  /// not also need a working app to ask it. It is the address the Play developer
  /// account is registered under, so the same mailbox that receives a store
  /// review question receives the breeder's. It replaces `support@salala.app`,
  /// which named a domain nobody had registered: a dead inbox on a Help page is
  /// worse than a personal one, because the breeder never learns the message
  /// went nowhere. A branded address can take over the day the domain exists,
  /// and only this line has to change.
  static const String supportEmail = 'www.toufik.bendjeddah@gmail.com';

  /// The Android package, which is what a store listing URL is built from.
  ///
  /// Deliberately not renamed with the product: an application id is permanent
  /// once published, invisible to a buyer, and changing it orphans every
  /// installed copy's data.
  static const String androidPackage = 'com.toufikben.ledger';

  /// The iTunes numeric id is empty because iOS is deferred; `openStoreListing`
  /// reads it only on Apple's platforms, and a blank value there is the plugin's
  /// own "no listing configured" rather than a wrong link.
  static const String appStoreId = '';
}
