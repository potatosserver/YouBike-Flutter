class AppEnvironment {
  static const String updateChannel = String.fromEnvironment(
    'UPDATE_CHANNEL',
    defaultValue: 'github',
  );

  static String get displayChannel {
    switch (updateChannel) {
      case 'github':
        return 'GitHub';
      case 'google_play':
        return 'Google Play';
      case 'web':
        return 'Web';
      case 'test':
        return 'Test';
      default:
        return updateChannel;
    }
  }
}
