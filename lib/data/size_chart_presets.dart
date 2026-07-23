/// Vocabulary + presets for the size-chart entry tool.
///
/// Item charts may only use measurement keys the *wearer* also has (from the
/// Bodygram scan / manual entry), otherwise there's nothing to compare against.
/// So this list is exactly that shared vocabulary, with friendly labels.
class SizeMeasurements {
  /// measurement key (Bodygram name) → friendly label shown in the editor.
  static const Map<String, String> labels = {
    'bustGirth': 'Chest / Bust',
    'underBustGirth': 'Under-bust',
    'acrossBackShoulderWidth': 'Shoulder width',
    'waistGirth': 'Waist',
    'hipGirth': 'Hip',
    'thighGirthR': 'Thigh',
    'insideLegLengthR': 'Inseam',
    'outseamR': 'Outseam',
    'outerArmLengthR': 'Sleeve (shoulder→wrist)',
    'backNeckPointToWristLengthR': 'Sleeve (nape→wrist)',
    'neckGirth': 'Neck',
  };

  static String label(String key) => labels[key] ?? key;

  /// All keys, in display order.
  static List<String> get all => labels.keys.toList();
}

/// A named starting set of measurements for a garment type. Fully editable in
/// the tool — this only pre-selects sensible fields so the user isn't staring
/// at a blank grid.
class SizePreset {
  final String name;
  final List<String> measurements;

  const SizePreset(this.name, this.measurements);

  static const List<SizePreset> all = [
    SizePreset("Men's top – short sleeve",
        ['bustGirth', 'acrossBackShoulderWidth']),
    SizePreset("Men's top – long sleeve",
        ['bustGirth', 'acrossBackShoulderWidth', 'outerArmLengthR']),
    SizePreset("Women's top – short sleeve",
        ['bustGirth', 'waistGirth', 'acrossBackShoulderWidth']),
    SizePreset("Women's top – long sleeve",
        ['bustGirth', 'waistGirth', 'acrossBackShoulderWidth', 'outerArmLengthR']),
    SizePreset("Women's dress", ['bustGirth', 'waistGirth', 'hipGirth']),
    SizePreset("Pants / Jeans",
        ['waistGirth', 'hipGirth', 'thighGirthR', 'insideLegLengthR']),
    SizePreset("Shorts / Skirt", ['waistGirth', 'hipGirth']),
    SizePreset("Jacket / Outerwear",
        ['bustGirth', 'acrossBackShoulderWidth', 'outerArmLengthR']),
  ];

  /// Best-guess preset for a product from its gender + category, so the editor
  /// opens on something close. The user can switch presets freely.
  static SizePreset guess(String gender, String category) {
    final c = category.toLowerCase();
    final female = gender.toLowerCase() == 'female';
    if (c.contains('pant') || c.contains('jean') || c.contains('trouser') ||
        c.contains('chino') || c.contains('legging')) {
      return all[5]; // Pants / Jeans
    }
    if (c.contains('short') || c.contains('skirt')) {
      return all[6]; // Shorts / Skirt
    }
    if (c.contains('dress') || c.contains('gown')) {
      return all[4]; // Women's dress
    }
    if (c.contains('jacket') || c.contains('coat') || c.contains('outer') ||
        c.contains('blazer')) {
      return all[7]; // Jacket / Outerwear
    }
    // Default to a top; short sleeve as the safe default (user flips to long).
    return female ? all[2] : all[0];
  }
}
