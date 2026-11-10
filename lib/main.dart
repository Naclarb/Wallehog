import 'app/app_strings.dart';
import 'package:flutter/material.dart';
import 'app/wallehog_app.dart';
import 'app/language_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'application/records_controller.dart';
import 'data/sqlite_record_repository.dart';
import 'app/home_widget_bridge.dart';

@pragma('vm:entry-point')
Future<void> widgetMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = RecordsController(await SqliteRecordRepository.open());
  await controller.load();
  await HomeWidgetBridge(controller).start();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Startup());
}

class Startup extends StatefulWidget {
  const Startup({super.key});
  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  final _language = LanguageController();
  HomeWidgetBridge? _widgetBridge;
  late Future<RecordsController> _opening = _open();
  Future<RecordsController> _open() async {
    await _language.load();
    final repository = await SqliteRecordRepository.open();
    final controller = RecordsController(repository);
    await controller.load();
    _widgetBridge = HomeWidgetBridge(controller);
    await _widgetBridge!.start();
    return controller;
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    controller: _language,
    child: ListenableBuilder(
      listenable: _language,
      builder: (context, _) => FutureBuilder<RecordsController>(
        future: _opening,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return WallehogApp(
              controller: snapshot.data!,
              languageController: _language,
            );
          }
          return MaterialApp(
            locale: _language.locale,
            supportedLocales: LanguageController.supported,
            localizationsDelegates: const [
              AppStrings.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr(context, '本地数据库暂时无法打开，数据不会被自动清除。')),
                            TextButton(
                              onPressed: () => setState(() {
                                _opening = _open();
                              }),
                              child: Text(tr(context, '重试')),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  @override
  void dispose() {
    _widgetBridge?.dispose();
    _language.dispose();
    super.dispose();
  }
}
