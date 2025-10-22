import 'package:example/demo.dart';
import 'package:flutter/material.dart';
import 'package:mostbyte_print/enums/connection_type.dart';
import 'package:mostbyte_print/esc_pos/esc_pos_utils_plus.dart';
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
  Future<void> printInIsolate(int i) async {
    // Ensure that you are calling services only from the main isolate
    // If needed, wrap your isolate function within the `compute` function.
    var mostbytePrint = MostbytePrint(
        connectionType: ConnectionType.usb,
        ip: "XP-58C",
        name: 'XP-58C',
        paperSize: PaperSize.mm58);
    var sss = await mostbytePrint.testTicket();
    var ticket = await mostbytePrint.generateReciept(
        orderType: "in_place",
        transferByCard: 0,
        orderNum: 3,
        orderId: 3342,
        comment: "Бар",
        employee: "Surayyo",
        percent: 12,
        time: "2024-11-27 12:34:44",
        orders: [
          {"name": "adsfasf", "price": 5000, "amount": 4.6, "isVisible": true},
          {
            "name": "adsfas23f",
            "price": 4000,
            "amount": 2.6,
            "isVisible": true
          },
          {"name": "333", "price": 15000, "amount": 4, "isVisible": false},
          {"name": "r4234", "price": 25000, "amount": 42.33, "isVisible": true}
        ],
        hours: 3,
        minutes: 3,
        tableName: "kabina 2",
        tablePrice: 25000,
        createdAt: "2024-11-27 12:34:44",
        closedAt: "2024-11-27 14:24:14",
        allSum: 140000,
        cash: 90000,
        terminal: 50000,
        discount: 10000,
        companyName: "Turkiston milliy taomlari kafesi");

    // var ticket = await mostbytePrint.generateReciept(
    //   department: "desktop $i",
    //   orderId: 3,
    //   // comment: "Бар",
    //   employee: "Surayyo",
    //   time: DateTime.now().toString(),
    //   orders: [
    //     {"name": "Мороженое клубничный 100гр", "price": 45000, "amount": 4.6},
    //     {"name": "adsfasf", "price": 45000, "amount": 4.6}
    //   ],
    // );

    await mostbytePrint.printTicket(sss);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // for (var i = 0; i < 40; i++) {
          await printInIsolate(3);
          // print.disconnect();
          // }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
