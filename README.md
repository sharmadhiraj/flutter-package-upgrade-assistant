# Flutter Package Upgrade Assistant

A Dart script to assist in upgrading Flutter package versions in the `pubspec.yaml` file.

<hr/>

#### Important Note: Flutter's Built-in Command for Upgrades

With the release of Flutter 2.0, you can easily upgrade all the packages in your project to the
latest major versions by running the following command:

`flutter pub upgrade --major-versions`

This built-in command performs much of the functionality that this tool was originally designed to
do, making it easier to keep your pubspec.yaml up to date.

<hr/>

#### Prerequisites

Make sure you have Flutter installed.

#### Clone the Repository

`git clone https://github.com/sharmadhiraj/flutter-package-upgrade-assistant.git`

#### Running the Script

Assuming you have Flutter set up, you can run the script either by passing the pubspec.yaml file as
an argument:

`dart main.dart path/to/pubspec.yaml`

Or by executing the script from the directory where the pubspec.yaml file exists:

`dart path/to/flutter-package-upgrade-assistant/main.dart`

For more information, visit
the [GitHub repository](https://github.com/sharmadhiraj/flutter-package-upgrade-assistant).