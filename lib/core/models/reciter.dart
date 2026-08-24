/// Represents a Quran reciter.
class Reciter {
  final String id;
  final String name;
  final String style; // e.g. "Murattal", "Mujawwad"

  const Reciter({
    required this.id,
    required this.name,
    required this.style,
  });
}
