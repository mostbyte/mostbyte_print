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
        return 'CP866'; // fallback, будет переопределено в MostbytePrint
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
        return 'CP866'; // fallback, будет переопределено в MostbytePrint
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

/// Производители принтеров которые лучше работают с CP1251
const Set<String> _cp1251Vendors = {
  'xprinter',
};

/// Профили принтеров которые лучше работают с CP1251
const Set<String> _cp1251Profiles = <String>{};

/// Определяет лучшую кодировку на основе имени профиля или производителя
/// RONGTA принтеры используют CP866 (code page 6/7)
CyrillicEncoding detectBestEncoding(String? profileName, String? vendor) {
  final profileLower = profileName?.toLowerCase() ?? '';
  final vendorLower = vendor?.toLowerCase() ?? '';

  // Проверяем производителя для CP1251
  for (final v in _cp1251Vendors) {
    if (vendorLower.contains(v)) {
      return CyrillicEncoding.cp1251;
    }
  }

  // Проверяем профиль для CP1251
  for (final p in _cp1251Profiles) {
    if (profileLower.contains(p)) {
      return CyrillicEncoding.cp1251;
    }
  }

  // По умолчанию CP866 (работает для большинства принтеров включая RONGTA)
  return CyrillicEncoding.cp866;
}
