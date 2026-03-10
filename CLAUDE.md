# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mostbyte_print** — a Flutter package for printing ESC/POS receipts via network (TCP/IP), USB, and Bluetooth connections. Primarily targets Windows for USB printing (uses Win32 API and FFI). The package name in pubspec is `mostbyte_print`, the repo directory is `print_reciept`.

## Commands

```bash
# Get dependencies (run from project root)
flutter pub get

# Get dependencies for example app
cd example && flutter pub get

# Run the example app
cd example && flutter run

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Architecture

### Core Library (`lib/`)

- **`lib/print.dart`** — Main entry point. `MostbytePrint` class handles all receipt generation and printing. Takes `ConnectionType` (network/usb/bluetooth), `PaperSize`, and printer address. Contains methods for generating different receipt types (`generateReciept`, `generateCheck`, `generateShift`, `generateOrderCheck`, `testTicket`) and `printTicket()` to send bytes to printer.

- **`lib/usb_esc_printer_windows.dart`** — USB printing on Windows via FFI isolate. Uses `sendPrintRequest()` to send raw ESC/POS bytes to a named Windows printer through a background isolate.

- **`lib/esc_pos/`** — Forked/embedded ESC/POS utilities (originally from `esc_pos_utils`). Contains `Generator` class for building ESC/POS byte sequences, capability profiles, barcode/QR support, GBK codec for Chinese characters, and FFI bindings.

- **`lib/models/data_models/`** — Data models (`Shift`, `User`, `Earned`, `Filial`, `Company`, `Role`) used for shift report receipt generation. All have `fromJson`/`toJson` factories.

- **`lib/enums/`** — `ConnectionType` (network/bluetooth/usb), `BluetoothPrinterType`, `ConnectionResponse`.

### Key Design Patterns

- Receipt generation methods return `List<int>` (raw ESC/POS bytes), which are then sent via `printTicket()`.
- Cyrillic text encoding uses `CharsetConverter` with CP866 codepage throughout.
- USB printing on Windows uses Win32 `OpenPrinter`/`WritePrinter` API (in `printRawData`) or FFI native library via isolate.
- Network printing uses `flutter_esc_pos_network` (`PrinterNetworkManager`) with a 2-second connection timeout.
- Paper sizes: `PaperSize.mm58` and `PaperSize.mm80` affect column widths and character limits.

## Dependencies

- `flutter_esc_pos_network` — Network printer communication
- `charset_converter` — CP866 Cyrillic text encoding
- `intl` — Number formatting
- `ffi` + `win32` — Windows USB printer access via Win32 API
