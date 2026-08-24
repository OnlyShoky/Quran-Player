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
