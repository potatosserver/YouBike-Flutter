/// Translates GraphHopper route instructions.
/// Separated from RouteDetailPanel widget.
class RouteInstructionTranslator {
  const RouteInstructionTranslator();

  static const _zhMap = <String, String>{
    'Continue': '直行',
    'Turn left': '左轉',
    'Turn right': '右轉',
    'U-turn': '掉頭',
  };

  String translate(String instruction, String lang) {
    if (lang == 'en') return instruction;
    for (final entry in _zhMap.entries) {
      if (instruction.contains(entry.key)) {
        return instruction.replaceFirst(entry.key, entry.value);
      }
    }
    return instruction;
  }
}