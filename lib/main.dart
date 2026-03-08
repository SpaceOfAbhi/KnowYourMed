import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings_provider.dart';
import 'services/storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.initialize();

  final settings = SettingsProvider();
  await settings.loadSettings();

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const KnowYourMedApp(),
    ),
  );
}
