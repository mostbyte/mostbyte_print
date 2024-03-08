import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import '../esc_pos/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

class ESCPrinterService {
  final Uint8List? receipt;
  List<int>? _bytes;
  List<int>? get bytes => _bytes;
  PaperSize? _paperSize;
  CapabilityProfile? _profile;

  ESCPrinterService(this.receipt);

  Future<List<int>> getBytes({
    PaperSize paperSize = PaperSize.mm80,
    CapabilityProfile? profile,
    String name = "XP-N160I",
  }) async {
    List<int> bytes = [];
    _profile = profile ?? (await CapabilityProfile.load(name: name));
    _paperSize = paperSize;
    Generator generator = Generator(_paperSize!, _profile!);
    var decodeImage = img.decodeImage(receipt!);
    if (decodeImage == null) throw Exception('decoded image is null');
    final img.Image _resize =
        img.copyResize(decodeImage, width: _paperSize!.width);
    // img.Image originalImg =
    //     img.copyResize(decodeImage, width: 380, height: 130);
    // // fills the original image with a white background
    // img.fill(originalImg, color: img.ColorRgb8(255, 255, 255));
    // var padding = (originalImg.width - _resize.width) / 2;

    // //insert the image inside the frame and center it
    // drawImage(originalImg, _resize, dstX: padding.toInt());

    // // convert image to grayscale
    // var grayscaleImage = img.grayscale(originalImg);

    String dir = (await getApplicationDocumentsDirectory()).path;
    String fullPath = '$dir/abc.png';
    print("local file full path ${fullPath}");
    File file = File(fullPath);

    await file.writeAsBytes(img.encodePng(_resize));
    // bytes += generator.setGlobalCodeTable('CP1252');
    bytes += generator.drawer();
    bytes += generator.qrcode("asdfasdf");
    // bytes += generator.image(
    //   _resize,
    // );
    bytes += generator.imageRaster(_resize, align: PosAlign.center);
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.beep();
    return bytes;
  }
}
