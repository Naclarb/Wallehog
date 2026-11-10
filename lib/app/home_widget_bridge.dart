import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../application/home_widget_service.dart';
import '../application/records_controller.dart';

class HomeWidgetBridge with WidgetsBindingObserver {
  HomeWidgetBridge(this.controller) : service = HomeWidgetService(controller);
  static const channel = MethodChannel('dev.wallehog/widget');
  final RecordsController controller;
  final HomeWidgetService service;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'snapshot':
          if (!controller.busy) await controller.load();
          return service.snapshot();
        case 'save':
          return service.submit(
            Map<Object?, Object?>.from(call.arguments as Map),
          );
        default:
          throw MissingPluginException();
      }
    });
    controller.addListener(_publish);
    _publish();
    try {
      await channel.invokeMethod<void>('ready');
    } on MissingPluginException {
      // Non-Android hosts and tests have no desktop widget provider.
    }
  }

  void _publish() => unawaited(_send());
  Future<void> _send() async {
    try {
      await channel.invokeMethod<void>('publish', service.snapshot());
    } on MissingPluginException {
      // Unsupported host.
    } on PlatformException {
      // A launcher update must never turn a committed save into a failure.
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_publish);
    channel.setMethodCallHandler(null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !controller.busy) {
      unawaited(controller.load());
    }
  }
}
