/// Supported printer vendors.
/// Choose your printer vendor — the package automatically selects
/// the correct capability profile and Cyrillic encoding.
enum PrinterVendor {
  xprinter('XP-N160I', 'Xprinter'),
  rongta('RP80USE', 'Rongta'),
  sewoo('SLK-TS400', 'Sewoo'),
  epson('default', 'Epson'),
  zkteco('ZKP8001', 'ZKTeco'),
  hprt('TP806L', 'HPRT'),
  citizen('CT-S651', 'Citizen'),
  netum('NT-5890K', 'Netum'),
  zjiang('POS-5890', 'Zjiang'),
  sunmi('Sunmi-V2', 'Sunmi'),
  star('SP2000', 'Star Micronics'),
  epos('TEP-200M', 'EPOS'),
  other('default', 'Other');

  const PrinterVendor(this.profileName, this.displayName);

  /// The capability profile key used internally
  final String profileName;

  /// Human-readable vendor name for UI display
  final String displayName;

  /// Find vendor by name string (e.g. from saved settings)
  static PrinterVendor fromName(String name) {
    final lower = name.toLowerCase();
    return values.firstWhere(
      (v) => v.name.toLowerCase() == lower ||
          v.displayName.toLowerCase() == lower,
      orElse: () => PrinterVendor.other,
    );
  }
}
