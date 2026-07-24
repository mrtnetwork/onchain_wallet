import 'build.dart';

void main(List<String> extra) async {
  await Cli.run(["apk"]);
  final List<String> args = [
    "--no-rust",
    "--no-crypto-c",
    "--no-sqlite3",
    "--no-webview",
    "--universal",
    ...extra
  ];
  await Cli.run(["apk", ...args]);
}
