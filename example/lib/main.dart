import 'package:example/demo.dart';
import 'package:flutter/material.dart';
import 'package:mostbyte_print/print.dart';

void main() {
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
  // Move your printing logic here and call it asynchronously
  Future<void> printInIsolate(String printString) async {
    // Ensure that you are calling services only from the main isolate
    // If needed, wrap your isolate function within the `compute` function.
    var mostbytePrint = MostbytePrint(
      ip: '192.168.5.155',
      name: 'kassa',
    );
    var sss = await mostbytePrint.testTicket();
    var ticket = await mostbytePrint.generateReciept(
        orderId: 3,
        comment: "Бар",
        employee: "Surayyo",
        time: DateTime.now().toString(),
        orders: [
          {"name": "adsfasf", "price": 45000, "amount": 4.6},
          {"name": "adsfasf", "price": 45000, "amount": 4.6}
        ],
        allSum: 140000,
        cash: 90000,
        terminal: 50000,
        discount: 10000,
        companyName: "Turkiston");
    ;
    await mostbytePrint.printTicket(ticket);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // for (var i = 0; i < 40; i++) {
          String data = Demo.testPage("333");
          await printInIsolate(data);
          // print.disconnect();
          // }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
