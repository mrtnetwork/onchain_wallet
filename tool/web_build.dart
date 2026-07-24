import 'build.dart';

void main(List<String> extra) async {
  await Cli.run(["web", "--production", ...extra]);
  final List<String> args = [
    "--no-rust",
    "--no-crypto",
    "--no-context",
    "--no-worker",
    ...extra
  ];
  await Cli.run(["extension", ...args]);
  await Cli.run(["extension", "--firefox", ...args, "--no-script"]);
  await Cli.run(["extension", "--ie", ...args, "--no-script"]);
  await Cli.run(["extension", "--opera", ...args, "--no-script"]);
  await Cli.run(["extension", "--brave", ...args, "--no-script"]);
}
