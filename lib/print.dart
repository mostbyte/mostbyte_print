library print;

import 'package:pos_printer_manager/pos_printer_manager.dart';
import './utils/service.dart';
import 'package:webcontent_converter/webcontent_converter.dart';

/// A Calculator.
class Print {
  PaperSize paperSize;
  String ip;
  String name;
  CapabilityProfile? profile;
  Print(
      {required this.ip,
      required this.name,
      this.paperSize = PaperSize.mm80,
      this.profile});

  connectPrinter({required String printString}) async {
    NetWorkPrinter networkPrinter = NetWorkPrinter(
      id: ip,
      name: name,
      address: ip,
      type: 0,
    );
    var paperSize = PaperSize.mm80;
    profile = await CapabilityProfile.load(name: "default");
    NetworkPrinterManager manager =
        NetworkPrinterManager(networkPrinter, paperSize, profile!);
    await manager.connect();

    var _bytes = await WebcontentConverter.contentToImage(
      content: printString,
      executablePath: WebViewHelper.executablePath(),
    );
    if (manager.isConnected) {
      var service = ESCPrinterService(_bytes);
      var data = await service.getBytes(paperSize: paperSize, profile: profile);

      manager.writeBytes(data, isDisconnect: false);
    } else {
      manager.disconnect();

      return false;
    }
    manager.disconnect();
  }
}
