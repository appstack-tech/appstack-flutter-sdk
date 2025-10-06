/// Standard attribution events supported by the SDK.
/// 
/// The enum values follow the widely adopted SNAKE_CASE notation used by
/// mobile measurement partners (MMPs). The raw value sent over the wire is the
/// enum name itself (e.g. `EventType.addToCart` → "ADD_TO_CART").
/// 
/// For events that have synonymous names (e.g. signUp/register), both variants
/// are provided to maximize compatibility with existing integrations.
enum EventType {
  // MARK: - Lifecycle
  /// User installs the app (tracked automatically by the SDK).
  install,
  
  // MARK: - Authentication & account
  /// User logs in to an existing account.
  login,
  /// User signs up for a new account.
  signUp,
  /// Alias for signUp – kept for compatibility with some MMPs.
  register,
  
  // MARK: - Monetization
  /// User completes a purchase (often includes revenue & currency).
  purchase,
  /// Item added to the shopping cart.
  addToCart,
  /// Item added to the wishlist.
  addToWishlist,
  /// Checkout process started.
  initiateCheckout,
  /// User starts a free trial.
  startTrial,
  /// User subscribes to a paid plan.
  subscribe,
  
  // MARK: - Games / progression
  /// User starts a new level (games).
  levelStart,
  /// User completes a level (games).
  levelComplete,
  
  // MARK: - Engagement
  /// User completes the onboarding tutorial.
  tutorialComplete,
  /// User performs a search in the app.
  search,
  /// User views a specific product or item.
  viewItem,
  /// User views generic content (e.g. article, post).
  viewContent,
  /// User shares content from the app.
  share,
  
  // MARK: - Catch-all
  /// Custom application-specific event not covered above.
  custom,
}

/// Extension to convert Dart enum names to SNAKE_CASE for the native SDKs
extension EventTypeExtension on EventType {
  String get name {
    switch (this) {
      case EventType.install:
        return 'INSTALL';
      case EventType.login:
        return 'LOGIN';
      case EventType.signUp:
        return 'SIGN_UP';
      case EventType.register:
        return 'REGISTER';
      case EventType.purchase:
        return 'PURCHASE';
      case EventType.addToCart:
        return 'ADD_TO_CART';
      case EventType.addToWishlist:
        return 'ADD_TO_WISHLIST';
      case EventType.initiateCheckout:
        return 'INITIATE_CHECKOUT';
      case EventType.startTrial:
        return 'START_TRIAL';
      case EventType.subscribe:
        return 'SUBSCRIBE';
      case EventType.levelStart:
        return 'LEVEL_START';
      case EventType.levelComplete:
        return 'LEVEL_COMPLETE';
      case EventType.tutorialComplete:
        return 'TUTORIAL_COMPLETE';
      case EventType.search:
        return 'SEARCH';
      case EventType.viewItem:
        return 'VIEW_ITEM';
      case EventType.viewContent:
        return 'VIEW_CONTENT';
      case EventType.share:
        return 'SHARE';
      case EventType.custom:
        return 'CUSTOM';
    }
  }
}
