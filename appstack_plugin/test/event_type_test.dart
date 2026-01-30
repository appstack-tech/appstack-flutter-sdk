import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/event_type.dart';

void main() {
  group('EventType.name', () {
    test('install -> INSTALL', () {
      expect(EventType.install.name, 'INSTALL');
    });
    test('login -> LOGIN', () {
      expect(EventType.login.name, 'LOGIN');
    });
    test('signUp -> SIGN_UP', () {
      expect(EventType.signUp.name, 'SIGN_UP');
    });
    test('register -> REGISTER', () {
      expect(EventType.register.name, 'REGISTER');
    });
    test('purchase -> PURCHASE', () {
      expect(EventType.purchase.name, 'PURCHASE');
    });
    test('addToCart -> ADD_TO_CART', () {
      expect(EventType.addToCart.name, 'ADD_TO_CART');
    });
    test('addToWishlist -> ADD_TO_WISHLIST', () {
      expect(EventType.addToWishlist.name, 'ADD_TO_WISHLIST');
    });
    test('initiateCheckout -> INITIATE_CHECKOUT', () {
      expect(EventType.initiateCheckout.name, 'INITIATE_CHECKOUT');
    });
    test('startTrial -> START_TRIAL', () {
      expect(EventType.startTrial.name, 'START_TRIAL');
    });
    test('subscribe -> SUBSCRIBE', () {
      expect(EventType.subscribe.name, 'SUBSCRIBE');
    });
    test('levelStart -> LEVEL_START', () {
      expect(EventType.levelStart.name, 'LEVEL_START');
    });
    test('levelComplete -> LEVEL_COMPLETE', () {
      expect(EventType.levelComplete.name, 'LEVEL_COMPLETE');
    });
    test('tutorialComplete -> TUTORIAL_COMPLETE', () {
      expect(EventType.tutorialComplete.name, 'TUTORIAL_COMPLETE');
    });
    test('search -> SEARCH', () {
      expect(EventType.search.name, 'SEARCH');
    });
    test('viewItem -> VIEW_ITEM', () {
      expect(EventType.viewItem.name, 'VIEW_ITEM');
    });
    test('viewContent -> VIEW_CONTENT', () {
      expect(EventType.viewContent.name, 'VIEW_CONTENT');
    });
    test('share -> SHARE', () {
      expect(EventType.share.name, 'SHARE');
    });
    test('custom -> CUSTOM', () {
      expect(EventType.custom.name, 'CUSTOM');
    });
  });

  group('EventType enum', () {
    test('has expected number of values', () {
      expect(EventType.values.length, 18);
    });

    test('all values have SNAKE_CASE names', () {
      for (final value in EventType.values) {
        expect(value.name, equals(value.name.toUpperCase()));
        expect(value.name, isNot(contains(' ')));
      }
    });
  });
}
