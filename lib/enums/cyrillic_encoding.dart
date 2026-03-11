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
        return 'CP866'; // fallback — most universally supported
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
        return 'CP866'; // fallback — most universally supported
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

/// Профили/производители которые используют CP1251
const Set<String> _cp1251Profiles = {
  'RP80USE',
  'RP328',
  'RP326',
};

/// Определяет лучшую кодировку на основе имени профиля.
/// CP866 — наиболее универсальная кодировка, поддерживается большинством принтеров.
/// CP1251 — специфична для Rongta и некоторых других принтеров.
CyrillicEncoding detectBestEncoding(String? profileName, String? vendor) {
  final profileLower = profileName?.toLowerCase() ?? '';

  // Rongta принтеры — CP1251
  for (final p in _cp1251Profiles) {
    if (profileLower == p.toLowerCase()) {
      return CyrillicEncoding.cp1251;
    }
  }

  // Все остальные (Epson, Xprinter, Zjiang, generic и т.д.) — CP866
  return CyrillicEncoding.cp866;
}
