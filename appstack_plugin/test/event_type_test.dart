import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/event_type.dart';

void main() {
  group('EventType.rawValue', () {
    test('install -> INSTALL', () {
      expect(EventType.install.rawValue, 'INSTALL');
    });
    test('login -> LOGIN', () {
      expect(EventType.login.rawValue, 'LOGIN');
    });
    test('signUp -> SIGN_UP', () {
      expect(EventType.signUp.rawValue, 'SIGN_UP');
    });
    test('register -> REGISTER', () {
      expect(EventType.register.rawValue, 'REGISTER');
    });
    test('purchase -> PURCHASE', () {
      expect(EventType.purchase.rawValue, 'PURCHASE');
    });
    test('addToCart -> ADD_TO_CART', () {
      expect(EventType.addToCart.rawValue, 'ADD_TO_CART');
    });
    test('addToWishlist -> ADD_TO_WISHLIST', () {
      expect(EventType.addToWishlist.rawValue, 'ADD_TO_WISHLIST');
    });
    test('initiateCheckout -> INITIATE_CHECKOUT', () {
      expect(EventType.initiateCheckout.rawValue, 'INITIATE_CHECKOUT');
    });
    test('startTrial -> START_TRIAL', () {
      expect(EventType.startTrial.rawValue, 'START_TRIAL');
    });
    test('subscribe -> SUBSCRIBE', () {
      expect(EventType.subscribe.rawValue, 'SUBSCRIBE');
    });
    test('levelStart -> LEVEL_START', () {
      expect(EventType.levelStart.rawValue, 'LEVEL_START');
    });
    test('levelComplete -> LEVEL_COMPLETE', () {
      expect(EventType.levelComplete.rawValue, 'LEVEL_COMPLETE');
    });
    test('tutorialComplete -> TUTORIAL_COMPLETE', () {
      expect(EventType.tutorialComplete.rawValue, 'TUTORIAL_COMPLETE');
    });
    test('search -> SEARCH', () {
      expect(EventType.search.rawValue, 'SEARCH');
    });
    test('viewItem -> VIEW_ITEM', () {
      expect(EventType.viewItem.rawValue, 'VIEW_ITEM');
    });
    test('viewContent -> VIEW_CONTENT', () {
      expect(EventType.viewContent.rawValue, 'VIEW_CONTENT');
    });
    test('share -> SHARE', () {
      expect(EventType.share.rawValue, 'SHARE');
    });
    test('custom -> CUSTOM', () {
      expect(EventType.custom.rawValue, 'CUSTOM');
    });
  });

  group('EventType enum', () {
    test('has expected number of values', () {
      expect(EventType.values.length, 18);
    });

    test('all values have SNAKE_CASE raw values', () {
      for (final value in EventType.values) {
        expect(value.rawValue, equals(value.rawValue.toUpperCase()));
        expect(value.rawValue, isNot(contains(' ')));
      }
    });

    test('name is the Dart enum name, not the wire value', () {
      expect(EventType.addToCart.name, 'addToCart');
      expect(EventType.values.byName(EventType.addToCart.name),
          EventType.addToCart);
    });
  });
}
