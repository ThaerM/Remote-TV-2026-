/// Public identity and web addresses shown in the app. The privacy and
/// support pages are published from `docs/privacy-policy.html` and
/// `docs/support.html` - see docs/release/release-checklist.md.
abstract final class AppLinks {
  static const appName = 'Remote TV 2026';
  static const developerName = 'Thaer Mosa';
  static final website = Uri.parse('https://thaerm.github.io/');
  static final github = Uri.parse('https://github.com/ThaerM');
  static final privacyPolicy = Uri.parse(
    'https://thaerm.github.io/remote-tv-2026/privacy-policy.html',
  );
  static final support = Uri.parse(
    'https://thaerm.github.io/remote-tv-2026/support.html',
  );
}
