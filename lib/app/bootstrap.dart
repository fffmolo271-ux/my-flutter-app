import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';

import '../services/notification_service.dart';

class AppStartupConfig {
  final bool firebaseEnabled;

  const AppStartupConfig({required this.firebaseEnabled});
}

Future<AppStartupConfig> initializeApp() async {
  bool firebaseEnabled = false;

  try {
    await Hive.initFlutter();
    await openVaultBoxSafely();
  } catch (error, stackTrace) {
    debugPrint('Hive initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Firebase init is optional: if it fails, app still runs locally (guest/local mode).
  try {
    await Firebase.initializeApp();
    firebaseEnabled = true;
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // google_sign_in v6 no longer requires (and may not support) the old `GoogleSignIn.instance.initialize()` pattern.
  // Keep initialization best-effort; actual sign-in happens via CoreState.

  try {
    await NotificationService.initialize();
  } catch (error, stackTrace) {
    debugPrint('NotificationService initialization failed: $error');

    debugPrintStack(stackTrace: stackTrace);
  }

  // Schedule daily reminder using persisted values.
  try {
    if (Hive.isBoxOpen('vault')) {
      final box = Hive.box('vault');
      final reminderHour = box.get('dailyReminderHour', defaultValue: 8) as int;
      final reminderMinute = box.get('dailyReminderMinute', defaultValue: 0) as int;
      await NotificationService.scheduleDailyMotivation(hour: reminderHour, minute: reminderMinute);
    }
  } catch (error, stackTrace) {
    debugPrint('Daily reminder scheduling failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  return AppStartupConfig(firebaseEnabled: firebaseEnabled);
}

Future<void> openVaultBoxSafely() async {
  try {
    await Hive.openBox('vault');
  } catch (error) {
    debugPrint('Hive box open failed; attempting recovery: $error');
    try {
      await Hive.deleteBoxFromDisk('vault');
      await Hive.openBox('vault');
    } catch (recoveryError, recoveryStack) {
      debugPrint('Hive recovery failed: $recoveryError');
      debugPrintStack(stackTrace: recoveryStack);
      rethrow;
    }
  }
}

