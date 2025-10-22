class ClinicianProfile {
  const ClinicianProfile({
    required this.name,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;

  ClinicianProfile copyWith({
    String? name,
    String? photoUrl,
  }) {
    return ClinicianProfile(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
