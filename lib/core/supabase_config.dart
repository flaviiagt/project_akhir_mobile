
class SupabaseConfig {
  static const url = 'https://rptfuilqthcwdppksftd.supabase.co';
  static const anonKey = 'sb_publishable_bcZbRFqveRTXhyl0q4yYdw_XqhxEXtp';
  static bool get isSet => !url.contains('XXXX') && !anonKey.startsWith('ISI_');
}