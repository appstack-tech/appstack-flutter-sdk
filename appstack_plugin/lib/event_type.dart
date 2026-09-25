/// Standard attribution events supported by the SDK.
///
/// The enum values follow the widely adopted SNAKE_CASE notation used by
/// mobile measurement partners (MMPs). The value sent over the wire is
/// [rawValue] (e.g. `EventType.addToCart.rawValue` → "ADD_TO_CART").
///
/// For events that have synonymous names (e.g. signUp/register), both variants
/// are provided to maximize compatibility with existing integrations.
enum EventType {
  // MARK: - Lifecycle
  /// User installs the app (tracked automatically by the SDK).
  ///
  /// Passing this to `sendEvent` has no effect: both native SDKs discard a
  /// manual install event so it cannot inflate install counts.
  install('INSTALL'),

  // MARK: - Authentication & account
  /// User logs in to an existing account.
  login('LOGIN'),

  /// User signs up for a new account.
  signUp('SIGN_UP'),

  /// Alias for signUp – kept for compatibility with some MMPs.
  register('REGISTER'),

  // MARK: - Monetization
  /// User completes a purchase (often includes revenue & currency).
  purchase('PURCHASE'),

  /// Item added to the shopping cart.
  addToCart('ADD_TO_CART'),

  /// Item added to the wishlist.
  addToWishlist('ADD_TO_WISHLIST'),

  /// Checkout process started.
  initiateCheckout('INITIATE_CHECKOUT'),

  /// User starts a free trial.
  startTrial('START_TRIAL'),

  /// User subscribes to a paid plan.
  subscribe('SUBSCRIBE'),

  // MARK: - Games / progression
  /// User starts a new level (games).
  levelStart('LEVEL_START'),

  /// User completes a level (games).
  levelComplete('LEVEL_COMPLETE'),

  // MARK: - Engagement
  /// User completes the onboarding tutorial.
  tutorialComplete('TUTORIAL_COMPLETE'),

  /// User performs a search in the app.
  search('SEARCH'),

  /// User views a specific product or item.
  viewItem('VIEW_ITEM'),

  /// User views generic content (e.g. article, post).
  viewContent('VIEW_CONTENT'),

  /// User shares content from the app.
  share('SHARE'),

  // MARK: - Catch-all
  /// Custom application-specific event not covered above.
  custom('CUSTOM');

  const EventType(this.rawValue);

  /// The SNAKE_CASE value sent to the native SDKs (e.g. `"ADD_TO_CART"`).
  ///
  /// `name` is Dart's own enum name (`"addToCart"`), not the wire value.
  final String rawValue;
}
