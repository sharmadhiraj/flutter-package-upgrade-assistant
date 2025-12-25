import 'dart:convert';
import 'dart:io';

import 'package.dart';

late File pubspecFile;

void main(List<String> args) async {
  initializePubspecFile(args);
  final List<Package> packages = extractPackagesFromPubspec();
  final List<Package> updatedPackages = await fetchLatestVersionsForPackages(
    packages,
  );
  await updatePubspecFileWithNewVersions(updatedPackages);
  print(
    "Package upgrade process completed successfully. Thank you for using the Flutter Package Upgrade Assistant. Please consider rating it on GitHub.",
  );
  print("https://github.com/sharmadhiraj/flutter-package-upgrade-assistant");
}

List<Package> extractPackagesFromPubspec() {
  final String dependenciesSection = pubspecFile.readAsStringSync().split(
    RegExp(r'dependencies:|dev_dependencies:'),
  )[1];
  final List<String> dependencies = dependenciesSection.split("\n");
  final List<Package> packages = [];
  dependencies.forEach((dependency) {
    final String cleanedDependency = dependency.trim();
    if (cleanedDependency.isEmpty ||
        cleanedDependency == "flutter:" ||
        cleanedDependency == "sdk: flutter" ||
        !RegExp(r'^[a-z0-9_]+: .+$').hasMatch(cleanedDependency))
      return;
    final List<String> dependencyParts = cleanedDependency.split(":");
    if (dependencyParts.length != 2) return;
    packages.add(
      Package(
        raw: dependency,
        name: dependencyParts.first,
        version: dependencyParts[1].replaceAll("^", "").trim(),
      ),
    );
  });
  print("Found ${packages.length} packages in pubspec.yaml.");
  return packages;
}

Future<String?> fetchLatestVersionForPackage(String packageName) async {
  print("Checking for the latest version of the package: $packageName");
  final Uri url = Uri.parse("https://pub.dev/packages/$packageName");
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(url);
    final HttpClientResponse response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      String content = await utf8.decodeStream(response);
      final int startIndex = content.indexOf('class="title') + 14;
      final int endIndex = content.indexOf("span ", startIndex) - 2;
      content = content.substring(startIndex, endIndex);
      content = content.replaceAll("$packageName ", "").trim();
      print("Latest version of $packageName retrieved: $content");
      return content;
    } else {
      print(
        "Failed to fetch the latest version for $packageName. Status code: ${response.statusCode}",
      );
    }
  } catch (error) {
    print(
      "An error occurred while fetching the latest version for $packageName: $error",
    );
  } finally {
    client.close();
  }
  return null;
}

Future<List<Package>> fetchLatestVersionsForPackages(
  List<Package> packages,
) async {
  final List<Package> updatedPackages = await Future.wait(
    packages.map((pkg) async {
      final latest = await fetchLatestVersionForPackage(pkg.name);
      return pkg.copyWith(newVersion: latest);
    }),
  );
  print(
    "Checked ${updatedPackages.length} packages on pub.dev. Found updates for ${updatedPackages.where((pkg) => pkg.hasNewVersion()).length} packages.",
  );
  return updatedPackages;
}

Future<void> updatePubspecFileWithNewVersions(
  List<Package> updatedPackages,
) async {
  String pubspecContent = pubspecFile.readAsStringSync();
  for (Package package in updatedPackages) {
    if (package.hasNewVersion()) {
      print(
        "Updating ${package.name} from version ${package.version} to ${package.newVersion}",
      );
      pubspecContent = pubspecContent.replaceAll(
        package.raw,
        package.getNewVersionRaw(),
      );
    }
  }
  await pubspecFile.writeAsString(pubspecContent);
  print("pubspec.yaml updated with the latest package versions.");
}

void initializePubspecFile(List<String> args) {
  String filePath = "pubspec.yaml";
  if (args.isNotEmpty) {
    filePath = args.first;
    if (!filePath.endsWith("pubspec.yaml")) {
      filePath = "$filePath/pubspec.yaml".replaceAll("//", "/");
    }
    print("Using specified path for pubspec.yaml: $filePath");
  } else {
    print("No path specified. Using the current directory for pubspec.yaml.");
  }
  pubspecFile = File(filePath);
  if (!pubspecFile.existsSync()) {
    print("pubspec.yaml file not found at the specified path: $filePath");
    exit(0);
  }
}
