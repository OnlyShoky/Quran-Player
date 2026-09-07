/// Represents a Quran reciter.
class Reciter {
  final int id;
  final String name;
  final String style; // e.g. "Murattal", "Mujawwad"
  final String serverUrl;

  const Reciter({
    required this.id,
    required this.name,
    required this.style,
    required this.serverUrl,
  });

  String get shortName {
    final clean = name.replaceAll(RegExp(r'^(Dr\.|Sheikh|Shaykh)\s+', caseSensitive: false), '').trim();
    final parts = clean.split(' ');
    if (parts.isEmpty) return name;
    if (parts.length == 1) return parts[0];
    if ((parts[0].toLowerCase() == 'abdul' || parts[0].toLowerCase() == 'abdel' || parts[0].toLowerCase() == 'abu') && parts.length > 1) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts[0];
  }

  String get initials {
    final clean = name.replaceAll(RegExp(r'^(Dr\.|Sheikh|Shaykh)\s+', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'[\s\-]+'));
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  factory Reciter.fromJson(Map<String, dynamic> json) {
    String serverUrl = '';
    String style = '';

    if (json['moshaf'] != null && (json['moshaf'] as List).isNotEmpty) {
      final moshaf = json['moshaf'][0];
      serverUrl = moshaf['server'] ?? '';
      final moshafName = moshaf['name'] as String? ?? '';
      if (moshafName.toLowerCase().contains('mujawwad')) {
        style = 'Mujawwad';
      } else {
        style = 'Murattal';
      }
    }

    return Reciter(
      id: json['id'] as int,
      name: json['name'] as String,
      style: style,
      serverUrl: serverUrl,
    );
  }
}
