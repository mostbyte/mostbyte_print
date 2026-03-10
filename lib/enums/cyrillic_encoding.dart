/// Encoding types for Cyrillic text on thermal printers
enum CyrillicEncoding {
  /// Автоматическое определение на основе профиля принтера
  auto,

  /// CP866 (DOS Cyrillic) - works on most printers
  cp866,

  /// CP1251 (Windows-1251) - better for RONGTA and some other printers
  cp1251,
}

extension CyrillicEncodingExtension on CyrillicEncoding {
  /// Returns the code table name for ESC/POS command
  String get codeTableName {
    switch (this) {
      case CyrillicEncoding.auto:
        return 'CP1251'; // fallback — works on most common printers
      case CyrillicEncoding.cp866:
        return 'CP866';
      case CyrillicEncoding.cp1251:
        return 'CP1251';
    }
  }

  /// Returns the charset name for CharsetConverter
  String get charsetName {
    switch (this) {
      case CyrillicEncoding.auto:
        return 'windows-1251'; // fallback — works on most common printers
      case CyrillicEncoding.cp866:
        return 'CP866';
      case CyrillicEncoding.cp1251:
        return 'windows-1251';
    }
  }
}

CyrillicEncoding cyrillicEncodingFromString(String value) {
  return CyrillicEncoding.values.firstWhere(
    (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
    orElse: () => CyrillicEncoding.auto,
  );
}

/// Профили/производители которые используют CP866
const Set<String> _cp866Profiles = {
  'default',    // Epson-совместимые
  'TM-T88II',
  'TM-T88III',
  'TM-T88IV',
  'TM-T88V',
};

/// Определяет лучшую кодировку на основе имени профиля
/// Большинство дешевых принтеров (Rongta, Zjiang, Xprinter) работают с CP1251
/// Epson принтеры работают с CP866
CyrillicEncoding detectBestEncoding(String? profileName, String? vendor) {
  final profileLower = profileName?.toLowerCase() ?? '';

  // Epson и совместимые — CP866
  for (final p in _cp866Profiles) {
    if (profileLower == p.toLowerCase()) {
      return CyrillicEncoding.cp866;
    }
  }

  // Все остальные (Rongta, Xprinter, Zjiang и т.д.) — CP1251
  return CyrillicEncoding.cp1251;
}
