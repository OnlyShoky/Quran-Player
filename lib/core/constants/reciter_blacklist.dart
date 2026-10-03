/// Compile-time blacklist of verified broken Quran audio servers and paths.
///
/// This provides 0ms startup overhead, zero cellular data usage, and works
/// completely offline, preventing users from seeing or selecting reciters
/// whose audio streams return HTTP 404.
class ReciterBlacklist {
  ReciterBlacklist._();

  /// MP3Quran.net server path substrings that return HTTP 404.
  /// (e.g. Zakaria Hamamah `/zakariya/`, Alhusayni Al-Azazi `/3zazi/`, etc.)
  static const Set<String> blacklistedMp3QuranServerSubstrings = {
    '/3zazi/', // Alhusayni Al-Azazi (id: 11)
    '/afs/Rewayat-AlDorai-A-n-Al-Kisa-ai/', // Mishary Alafasi Al-Duri (id: 123)
    '/muamr/', // Muamar Indonesia (id: 128)
    '/malaysia/akil/', // Akhil Abdulhayy Rawa (id: 153)
    '/malaysia/zamri/', // Ustaz Zamri (id: 154)
    '/alshaik/', // Hussain Alshaik (id: 162)
    '/obaid/', // Nasser Al obaid (id: 166)
    '/wasel/Rewayat-Hafs-A-n-Assem/', // Wasel Almethen (id: 167)
    '/malaysia/rziah/', // Rodziah Abdulrahman (id: 183)
    '/malaysia/rogiah/', // Rogayah Sulong (id: 184)
    '/malaysia/mamat/', // Sapinah Mamat (id: 185)
    '/malaysia/sideen/', // Saidin Abdulrahman (id: 187)
    '/wishear/', // Wishear Hayder Arbili (id: 209)
    '/m-dibirov/Rewayat-Hafs-A-n-Assem/', // Mohammad Dibirov (id: 21200)
    '/musali/', // Salah Musali (id: 246)
    '/sharekh/', // Khalid Alsharekh (id: 247)
    '/deban/Rewayat-Khalaf-A-n-Hamzah/', // Ahmad Deban Khalaf (id: 265)
    '/bl3/', // Rachid Belalya Hafs (id: 27)
    '/okasha/Rewayat-AlDorai-A-n-Al-Kisa-ai/', // Okasha Kameny Al-Duri (id: 272)
    '/a_maasaraawi/Rewayat-Rawh-A-n-Yakoob-Alhadrami/', // Ahmad Issa Rawh (id: 278)
    '/zakariya/', // Zakaria Hamamah (id: 28) - 404 confirmed
    '/a_alaskar/Rewayat-Hafs-A-n-Assem/', // Abdulmalik Alaskar (id: 303)
    '/a-almishal/Rewayat-Hafs-A-n-Assem/', // Abdullah Al-Mishal (id: 306)
    '/sami_dosr/', // Sami Al-Dosari (id: 35)
    '/shaban/', // Shaban Al-Sayiaad (id: 37)
    '/saud/', // Ahmad Saud (id: 7)
    '/abo_hashim/', // Ali Abo-Hashim (id: 73)
    '/fahad_otibi/', // Fahad Al-Otaibi (id: 82)
    '/lafi/', // Lafi Al-Oni (id: 85)
  };

  /// QuranicAudio relative path prefixes that return HTTP 404 (broken subsets/dirs).
  static const Set<String> blacklistedQuranicAudioPaths = {
    'sa3d_al-ghaamidi/hidayah/',
    'maher_almu3aiqly/year1424-1425/',
    'jibreen/jibreen_1426-1427/',
    'dr.shawqy_7amed/mujawwad/',
    'khalid_alghamdi/',
  };

  /// Checks if a given MP3Quran server URL is blacklisted as broken.
  static bool isMp3QuranServerBroken(String serverUrl) {
    if (serverUrl.isEmpty) return true;
    for (final pattern in blacklistedMp3QuranServerSubstrings) {
      if (serverUrl.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a given QuranicAudio relative path is blacklisted as broken.
  static bool isQuranicAudioPathBroken(String relativePath) {
    if (relativePath.isEmpty) return true;
    final normalized = relativePath.trim().replaceAll('\\', '/');
    for (final pattern in blacklistedQuranicAudioPaths) {
      if (normalized.startsWith(pattern) || normalized.contains(pattern)) {
        return true;
      }
    }
    return false;
  }
}
