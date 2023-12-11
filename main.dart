import 'dart:convert';
import 'dart:io';

import 'package.dart';

late File file;

void main(List<String> args) async {
  initFile(args);
  final List<Package> packages = getPackages();
  final List<Package> updatedPackages =
      await getLatestVersionForPackages(packages);
  await updatePackageVersionsInPubspecFile(updatedPackages);
  print("Packages upgrade complete. Thanks for using. Please rate on GitHub.");
  print("https://github.com/sharmadhiraj/flutter-package-upgrade-assistant");
}

List<Package> getPackages() {
  final String dependenciesSection = file
      .readAsStringSync()
      .split(RegExp(r'dependencies:|dev_dependencies:'))[1];
  final List<String> dependencies = dependenciesSection.split("\n");
  final List<Package> packages = [];
  dependencies.forEach((orgItem) {
    final String item = orgItem.replaceAll(" ", "");
    if (item.isEmpty || item == "flutter:" || item == "sdk:flutter") return;
    final List<String> itemSplit = item.split(":");
    if (itemSplit.length != 2) return;
    packages.add(
      Package(
        raw: orgItem,
        name: itemSplit.first,
        version: itemSplit[1].replaceAll("^", ""),
      ),
    );
  });
  print("Retrieved ${packages.length} packages from pubspec.yaml");
  return packages;
}

Future<String?> getLatestVersionForPackage(String packageName) async {
  final url = Uri.parse("https://pub.dev/packages/$packageName");
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      String content = await utf8.decodeStream(response);
      final int startIndex = content.indexOf('class="title') + 14;
      final int endIndex = content.indexOf("span ", startIndex) - 2;
      content = content.substring(startIndex, endIndex);
      content = content.replaceAll("$packageName ", "");
      return content;
    } else {
      print("Failed to fetch data. Status code: ${response.statusCode}");
    }
  } catch (error) {
    print("Error: $error");
  } finally {
    client.close();
  }
  return null;
}

Future<List<Package>> getLatestVersionForPackages(
    List<Package> packages) async {
  final List<Package> updatedPackages = [];
  for (int i = 0; i < packages.length; i++) {
    final Package package = packages[i];
    final String? newVersion = await getLatestVersionForPackage(package.name);
    package.newVersion = newVersion;
    updatedPackages.add(package);
  }
  print(
    "Got ${updatedPackages.length} packages from pub.dev, ${updatedPackages.where((item) => item.hasNewVersion()).length} have updates.",
  );
  return updatedPackages;
}

Future<void> updatePackageVersionsInPubspecFile(
    List<Package> updatedPackages) async {
  String pubspecFileContent = file.readAsStringSync();
  updatedPackages.forEach((package) {
    if (package.hasNewVersion()) {
      print(
        "${package.name} package updated to ${package.newVersion} from ${package.version}",
      );
      pubspecFileContent = pubspecFileContent.replaceAll(
        package.raw,
        package.getNewVersionRaw(),
      );
    }
  });
  await file.writeAsString(pubspecFileContent);
  print("pubspec.yaml updated with new package versions.");
}

void initFile(List<String> arguments) {
  String filePath = "pubspec.yaml";
  if (arguments.length > 0) {
    filePath = arguments.first;
    if (!filePath.endsWith("pubspec.yaml")) {
      filePath = "$filePath/pubspec.yaml".replaceAll("//", "/");
    }
    print("Using provided arguments as filepath for pubspec.yaml: $filePath");
  } else {
    print(
      "No arguments provided, assuming pubspec.yaml exists in the current directory",
    );
  }
  file = File(filePath);
  if (!file.existsSync()) {
    print("File does not exists on given path : $filePath");
    exit(0);
  }
}
