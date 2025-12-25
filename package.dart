import 'dart:convert';

class Package {
  final String raw;
  final String name;
  final String version;
  final String? newVersion;

  const Package({
    required this.raw,
    required this.name,
    required this.version,
    this.newVersion,
  });

  Package copyWith({String? newVersion}) {
    return Package(
      raw: raw,
      name: name,
      version: version,
      newVersion: newVersion ?? this.newVersion,
    );
  }

  @override
  String toString() {
    return jsonEncode({
      "raw": raw,
      "name": name,
      "version": version,
      "new version": newVersion,
    });
  }

  bool hasNewVersion() {
    return newVersion != null && version != newVersion;
  }

  String getNewVersionRaw() {
    return raw.replaceAll(version, newVersion ?? version);
  }
}
