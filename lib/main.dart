import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI and local storage
  await initDependencies();

  // Initialize notification service
  await getIt<NotificationService>().init();
  

  runApp(const AzkariApp());
}
