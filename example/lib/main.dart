import 'package:example/demo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mostbyte_print/print.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Print Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Print Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> printInIsolate(String printString) async {
    // Ensure that you are calling services only from the main isolate
    // If needed, wrap your isolate function within the `compute` function.
    var mostbytePrint = MostbytePrint(
      ip: '192.168.5.155',
      name: 'kassa',
    );
    await mostbytePrint.connectPrinter(printString: printString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // for (var i = 0; i < 40; i++) {
          String data = Demo.testPage("");
          // Call the isolate via compute
          await printInIsolate(data);

          // print.disconnect();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
