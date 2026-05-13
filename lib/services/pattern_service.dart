/// Utility for normalising task text before frequency tracking.
abstract final class PatternService {
  /// Lowercases, trims, and strips punctuation — used both when recording
  /// a task and when comparing existing task titles to suggestion keys.
  static String normalize(String text) =>
      text.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
}
