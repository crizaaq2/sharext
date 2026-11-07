import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sx_core/sx_core.dart';
import 'package:sharext/features/state/app_state.dart';

void main() {
  test('a text message reaches delivered over the in-memory link', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final AppController controller = container.read(
      appControllerProvider.notifier,
    );
    final String? reason = await controller.connect('axmed');
    expect(reason, isNull);

    await controller.send('axmed', 'Salaan!');
    AppModel afterSend = container.read(appControllerProvider);
    ChatMessage sent = afterSend.messages.last;
    expect(sent.text, 'Salaan!');
    expect(
      sent.status,
      anyOf(MessageStatus.sent, MessageStatus.delivered),
      reason: 'persist first, then send; never queued after a live link',
    );

    // The peer persists, then acknowledges; the receipt travels back.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    afterSend = container.read(appControllerProvider);
    sent = afterSend.messages.last;
    expect(sent.status, MessageStatus.delivered);
  });

  test('a device without ShAre XT keeps the message queued', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final AppController controller = container.read(
      appControllerProvider.notifier,
    );
    await controller.send('printer', 'Hello?');

    final AppModel model = container.read(appControllerProvider);
    expect(model.messages.last.status, MessageStatus.queued);
    expect(model.queuedCount, 1);
    expect(
      model.messages.last.outgoing,
      isTrue,
      reason: 'the sender keeps it; we never pretend it was sent',
    );
  });

  test('empty text is not enqueued', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final AppController controller = container.read(
      appControllerProvider.notifier,
    );
    final int before = container.read(appControllerProvider).messages.length;
    await controller.send('axmed', '   ');
    expect(container.read(appControllerProvider).messages, hasLength(before));
  });

  test('language and theme change the model', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final AppController controller = container.read(
      appControllerProvider.notifier,
    );
    controller.setLocale(const Locale('so'));
    expect(container.read(appControllerProvider).localeCode, 'so');
    controller.setLocale(const Locale('ar'));
    expect(container.read(appControllerProvider).localeCode, 'ar');
    controller.setLocale(null);
    expect(container.read(appControllerProvider).localeCode, isNull);

    controller.setThemeMode(ThemeMode.light);
    expect(container.read(appControllerProvider).themeMode, ThemeMode.light);
  });

  test('the demo data ships three people who have ShAre XT', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final AppModel model = container.read(appControllerProvider);
    expect(model.aroundPeers, hasLength(3));
    expect(model.otherDevices, hasLength(2));
    expect(model.displayName, isEmpty);
  });
}
