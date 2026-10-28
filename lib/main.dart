import 'package:flutter/material.dart';
import 'app/wallehog_app.dart';
import 'application/records_controller.dart';
import 'data/sqlite_record_repository.dart';

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
  late Future<RecordsController> _opening = _open();
  Future<RecordsController> _open() async {
    final repository = await SqliteRecordRepository.open();
    final controller = RecordsController(repository);
    await controller.load();
    return controller;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RecordsController>(
    future: _opening,
    builder: (context, snapshot) {
      if (snapshot.hasData) return WallehogApp(controller: snapshot.data!);
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('本地数据库暂时无法打开，数据不会被自动清除。'),
                      TextButton(
                        onPressed: () => setState(() {
                          _opening = _open();
                        }),
                        child: const Text('重试'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
