library print;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import './pos_manager.dart';
import './utils/service.dart';
import 'package:webcontent_converter/webcontent_converter.dart';

class MostbytePrint {
  PaperSize paperSize;
  String ip;
  String name;
  CapabilityProfile? profile;
  MostbytePrint(
      {required this.ip,
      required this.name,
      this.paperSize = PaperSize.mm80,
      this.profile});
  NetworkPrinterManager? manager;

  connectPrinter({required String printString}) async {
    NetWorkPrinter networkPrinter = NetWorkPrinter(
      id: ip,
      name: name,
      address: ip,
    );
    var paperSize = PaperSize.mm80;
    profile = await CapabilityProfile.load();
    manager = NetworkPrinterManager(networkPrinter, paperSize, profile!);
    await manager?.connect();

    if (manager!.isConnected) {
      var _bytes = await WebcontentConverter.contentToImage(
        content: printString,
        executablePath: WebViewHelper.executablePath(),
      );
      var service = ESCPrinterService(_bytes);
      var data = await service.getBytes();
      manager!.writeBytes(data);
      // manager.disconnect();
    } else {
      manager!.disconnect();

      return false;
    }
    // manager.disconnect();
  }

  disconnect() {
    manager?.disconnect();
  }
}
