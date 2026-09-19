/// A launchable app/channel on a [TvDevice] (e.g. Netflix, YouTube).
class TvApplication {
  const TvApplication({required this.id, required this.name, this.iconKey});

  final String id;
  final String name;
  final String? iconKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvApplication &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconKey == other.iconKey;

  @override
  int get hashCode => Object.hash(id, name, iconKey);
}
