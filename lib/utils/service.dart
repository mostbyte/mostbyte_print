import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../esc_pos/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

class ESCPrinterService {
  final Uint8List? receipt;
  PaperSize? _paperSize;
  CapabilityProfile? _profile;

  ESCPrinterService(this.receipt);

  Future<List<int>> getBytes({
    PaperSize paperSize = PaperSize.mm80,
    CapabilityProfile? profile,
    String name = 'default',
  }) async {
    List<int> bytes = [];
    _profile = profile ?? (await CapabilityProfile.load(name: name));
    _paperSize = paperSize;

    assert(receipt != null);
    assert(_paperSize != null);
    assert(_profile != null);
    Generator generator = Generator(_paperSize!, _profile!);
    final img.Image _resize =
        img.copyResize(img.decodeImage(receipt!)!, width: _paperSize!.width);

    // String dir = (await getApplicationDocumentsDirectory()).path;
    // String fullPath = '$dir/abc.png';
    // print("local file full path ${fullPath}");
    // File file = File(fullPath);
    // await file.writeAsBytes(img.encodePng(_resize));

    bytes += generator.imageRaster(_resize);
    bytes += generator.feed(2);
    bytes += generator.cut();
    // bytes += generator.beep();
    return bytes;
  }
}
