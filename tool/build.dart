// ignore_for_file: unnecessary_string_escapes, library_private_types_in_public_api, avoid_print
//
// Build tool for the on_chain_wallet Flutter app.
//
// Usage:
//   dart run tool/build.dart <command> [flags]
//
// Commands:
//   web         Build the plain Flutter web app.
//   extension   Build a browser extension (chrome/firefox/opera/ie).
//   apk         Build the Android APK.
//   macos       Build the macOS app.
//   windows     Build the Windows app.
//   linux       Build the Linux app (zip + .deb).
//   ios         Build the iOS app.
//   clean       flutter clean && flutter pub get.
//
// Run `dart run tool/build.dart <command> --help` for command-specific flags.
//
// Examples:
//   dart run tool/build.dart web --release --wasm
//   dart run tool/build.dart extension --firefox --release
//   dart run tool/build.dart extension --chrome --script-content --debug
//   dart run tool/build.dart apk --release
//   dart run tool/build.dart macos --release
//   dart run tool/build.dart ios --release
//   dart run tool/build.dart clean

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
// import 'package:on_chain_wallet/app/core.dart';

// import 'package:on_chain_wallet/app/core.dart';

/// ---------------------------------------------------------------------------
/// Config
/// ---------------------------------------------------------------------------
/// All paths/constants the build depends on live here. Anything machine
/// specific (like the rust crate locations) can be overridden from the CLI
/// so this file isn't tied to one developer's home directory.
abstract class BuildConfig {
  static const String extensionSourceDir = 'requirement/extensions/';
  static const String webviewSourceDir = 'requirement/webview/';
  static const String browserSourceDir = 'requirement/browser/';
  static const String dmgInstallerDir = 'requirement/dmg_installer/';

  static const String jsScriptsDir = 'js_scripts';
  static const String webScriptAssetsDir = 'assets/web_scripts';
  static const String webViewAssetsDir = 'assets/webview';
  static const String buildWebDir = 'build/web/';
  static const String buildWebAssetDir = 'build/web/assets/assets/web_scripts';
  static const String buildWebFlutterAssetDir =
      'build/flutter_assets/assets/web_scripts';

  static const String webOutDir = 'web';
  static const String defaultReleaseLocation = 'release/';
  static const String productionBaseHref = '/onchain_wallet/';

  static const String assetPath = "assets/image/logo_256x256.png";

  static const String zkGitUrl = "https://github.com/mrtnetwork/zk.git";
  static const String netSdkGitUrl =
      "https://github.com/mrtnetwork/net_sdk.git";
  static const String cryptoCGitUrl =
      "https://github.com/mrtnetwork/onchain_crypto_c.git";
  static const String sqlite3 =
      "https://github.com/utelle/SQLite3MultipleCiphers.git";
  static String webScriptAsset(String fileName) =>
      '$webScriptAssetsDir/$fileName'.normalizePath;
  static String webViewAssets(String fileName) =>
      '$webViewAssetsDir/$fileName'.normalizePath;
  static const String appName = "on_chain_wallet";
  static const String packageName = "com.mrtnetwork.on_chain_wallet";

  /// Default minimum Android API used when resolving the NDK clang.
  static const int defaultAndroidApi = 23;

  /// Minimum iOS deployment target used for native C/Rust builds.
  static const String iosDeploymentTarget = '12.0';
}

class CompilerError implements Exception {
  final String message;
  final Map<String, dynamic>? details;
  const CompilerError(this.message, {this.details});

  @override
  String toString() {
    return "CompilerError($message)";
  }
}

/// ---------------------------------------------------------------------------
/// Loging
/// ---------------------------------------------------------------------------
class Log {
  static void info(Object? message) => print('\x1B[33m$message\x1B[0m');
  static void success(Object? message) => print('\x1B[32m$message\x1B[0m');
  static void error(Object? message) => print('\x1B[31m$message\x1B[0m');
}

/// ---------------------------------------------------------------------------
/// Process execution
/// ---------------------------------------------------------------------------
class BuildFailure implements Exception {
  BuildFailure(this.command, this.exitCode);
  final String command;
  final int exitCode;

  @override
  String toString() => 'BuildFailure: "$command" exited with code $exitCode';
}

class ProcessRunner {
  /// Runs [command] with [args], streaming stdout/stderr live, and throws
  /// [BuildFailure] on a non-zero exit code.
  static Future<void> run(String command, List<String> args,
      {String? workingDirectory, Map<String, String>? environment}) async {
    final label = ([command, ...args]).join(' ');
    Log.info(
        '▶ $label${workingDirectory != null ? ' (in $workingDirectory)' : ''}');

    final process = await Process.start(command, args,
        runInShell: Platform.isWindows,
        workingDirectory: workingDirectory,
        environment: environment);
    await Future.wait([
      stdout.addStream(process.stdout),
      stderr.addStream(process.stderr),
    ]);
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      Log.error('✗ $label failed with exit code $exitCode');
      throw BuildFailure(label, exitCode);
    }
    Log.success('✓ $label');
  }

  static Future<void> flutterClean() async {
    await run('flutter', ['clean']);
    await run('flutter', ['pub', 'get']);
  }

  static Future<void> servePython(String directory, {int port = 8000}) async {
    await run('python3', ['-m', 'http.server', '$port'],
        workingDirectory: directory);
  }
}

/// ---------------------------------------------------------------------------
/// Filesystem helpers
/// ---------------------------------------------------------------------------
class FsUtils {
  /// Copies top-level files from [source] into [destination] (non-recursive).
  /// If [extension] is given, only files ending with it are copied.
  static void copyFiles(Directory source, Directory destination,
      {String? extension}) {
    if (!destination.existsSync()) destination.createSync(recursive: true);

    for (final entity in source.listSync(recursive: false)) {
      if (entity is! File) continue;
      if (extension != null && !entity.path.endsWith(extension)) continue;
      final target = File(
          '${destination.path}/${entity.uri.pathSegments.last}'.normalizePath);
      target.writeAsBytesSync(entity.readAsBytesSync());
    }
  }

  /// Recursively copies [source] into [destination]. If [cleanDestination] is
  /// true, [destination] is deleted first.
  static void copyDirectory(
    Directory source,
    Directory destination, {
    bool cleanDestination = false,
  }) {
    if (cleanDestination && destination.existsSync()) {
      destination.deleteSync(recursive: true);
    }
    destination.createSync(recursive: true);

    for (final entity in source.listSync(recursive: false)) {
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (entity is Directory) {
        copyDirectory(
            entity, Directory('${destination.path}/$name'.normalizePath));
      } else if (entity is File) {
        File('${destination.path}/$name'.normalizePath)
            .writeAsBytesSync(entity.readAsBytesSync());
      }
    }
  }

  /// Copies then deletes the source (i.e. "move").
  static void moveDirectory(
    Directory source,
    Directory destination, {
    bool cleanDestination = false,
  }) {
    copyDirectory(source, destination, cleanDestination: cleanDestination);
    source.deleteSync(recursive: true);
  }

  static void deleteFile(String path) {
    final file = File(path.normalizePath);
    if (file.existsSync()) file.deleteSync();
  }

  static void deleteFiles(Iterable<String> paths) => paths.forEach(deleteFile);

  static Directory webScriptAssetsDirectory() =>
      Directory(BuildConfig.webScriptAssetsDir.normalizePath);

  /// Copies the compiled web-script assets into both build output locations
  /// Flutter expects them in.
  static void publishWebScriptAssets() {
    copyDirectory(
        webScriptAssetsDirectory(), Directory(BuildConfig.buildWebAssetDir));
    copyDirectory(
      webScriptAssetsDirectory(),
      Directory(BuildConfig.buildWebFlutterAssetDir.normalizePath),
    );
    Log.success(
        'web-script assets published to ${BuildConfig.buildWebFlutterAssetDir}');
  }

  static void publishFile(
      {required String source,
      required String destination,
      required String name}) {
    final file = File(source.normalizePath);
    if (!file.existsSync()) {
      throw Exception("source file missing");
    }
    final d = File(destination.normalizePath);
    if (d.existsSync()) {
      d.deleteSync();
    }
    d.createSync(recursive: true);
    file.copySync(destination.normalizePath);
    Log.success('$name file published to ${d.path}');
  }

  static Future<void> zipDirectory({
    required String sourceDir,
    required String outputZip,
  }) async {
    final encoder = ZipFileEncoder();
    encoder.create(outputZip);

    await encoder.addDirectory(Directory(sourceDir.normalizePath));

    await encoder.close();
  }

  /// Directory portion of a "/"-separated relative path (".", when none).
  static String dirOf(String p) {
    final i = p.lastIndexOf(path.separator);
    return i <= 0 ? '.' : p.substring(0, i);
  }
}

class _DebFileBuilder {
  /// Debian policy requires the `Package:` name to be at least two characters,
  /// start with an alphanumeric, and contain only lowercase letters, digits,
  /// and the symbols '-', '+' and '.'. Names like "onchain_wallet" or ones
  /// with uppercase letters are rejected by dpkg-deb, so normalize here.
  static String sanitizeDebPackageName(String raw) {
    var name = raw.toLowerCase();
    // Replace every disallowed character (e.g. '_', spaces) with '-'.
    name = name.replaceAll(RegExp(r'[^a-z0-9+.-]'), '-');
    // Collapse repeated separators for a cleaner name.
    name = name.replaceAll(RegExp(r'-{2,}'), '-');
    // Must start with an alphanumeric; strip leading separators.
    name = name.replaceAll(RegExp(r'^[^a-z0-9]+'), '');
    // Trim trailing separators too.
    name = name.replaceAll(RegExp(r'[-+.]+$'), '');
    if (name.length < 2) {
      throw CompilerError(
          'Cannot derive a valid Debian package name from "$raw". '
          'Provide a name with at least two alphanumeric characters.');
    }
    return name;
  }

  static Future<String> getDebianArchitecture() async {
    try {
      final result = await Process.run('dpkg', ['--print-architecture']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}

    final result = await Process.run('uname', ['-m']);
    switch ((result.stdout as String).trim()) {
      case 'x86_64':
        return 'amd64';
      case 'aarch64':
        return 'arm64';
      case 'armv7l':
        return 'armhf';
      case 'i686':
        return 'i386';
      default:
        throw UnsupportedError('Unsupported architecture');
    }
  }

  static Future<void> createDebFile(
      {required String displayName,
      required String version,
      required String execName,
      required String packageName,
      required String applicationId,
      required String iconPath,
      required Directory outDir,
      required Directory bundleDirectory}) async {
    Directory createPackageFolders(String name) {
      final directory = Directory("${outDir.path}/$name".normalizePath);
      directory.createSync(recursive: true);
      return directory;
    }

    final arch = await getDebianArchitecture();

    final debian = createPackageFolders("DEBIAN");
    final opt = createPackageFolders("opt/$packageName");
    final application = createPackageFolders("usr/share/applications");
    // hicolor is the standard theme every desktop environment searches.
    final iconApps =
        createPackageFolders("usr/share/icons/hicolor/256x256/apps");
    // Legacy fallback: many environments show the icon from here even before
    // the icon cache is (re)built, so this makes the icon reliable.
    final pixmaps = createPackageFolders("usr/share/pixmaps");
    createPackageFolders("usr/local/bin");
    FsUtils.copyDirectory(bundleDirectory, opt);

    // Make the launcher binary executable (copyDirectory may drop the bit).
    final launcher = File("${opt.path}/$execName".normalizePath);
    if (launcher.existsSync()) {
      await Process.run("chmod", ["0755", launcher.path]);
    }

    final desktopContent = '''[Desktop Entry]
Version=1.0
Type=Application
Name=$displayName
GenericName=$displayName
Comment=A Flutter desktop application
Exec=/opt/$packageName/$execName
Icon=$applicationId
Terminal=false
Categories=Utility;
StartupNotify=true
StartupWMClass=$execName
''';
    // The .desktop filename should match the application id (reverse-DNS is
    // preferred by desktop environments) and must be world-readable (0644).
    final desktopFile =
        File('${application.path}/$applicationId.desktop'.normalizePath)
          ..createSync(recursive: true)
          ..writeAsStringSync(desktopContent);
    await Process.run("chmod", ["0644", desktopFile.path]);

    // Install the icon under hicolor AND pixmaps so it resolves with or
    // without an up-to-date icon cache. Icon= in the .desktop entry must match
    // these filenames (minus extension): "$applicationId".
    final appIcon = File(iconPath.normalizePath);
    if (!appIcon.existsSync()) {
      throw CompilerError('Icon not found at "$iconPath". '
          'Provide a 256x256 PNG so the app icon shows in the menu.');
    }
    appIcon.copySync("${iconApps.path}/$applicationId.png");
    appIcon.copySync("${pixmaps.path}/$applicationId.png");

    final debPackageName = sanitizeDebPackageName(packageName);

    // AppStream metadata: this is what graphical installers (GNOME Software,
    // KDE Discover, the "Software Install" dialog) read to show a proper
    // title, description, and icon DURING installation. Without it they fall
    // back to the raw Package name ("on-chain-wallet") and a generic icon.
    final metainfoDir = createPackageFolders("usr/share/metainfo");
    final metainfoContent = '''<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>$applicationId</id>
  <metadata_license>CC0-1.0</metadata_license>
  <name>$displayName</name>
  <summary>A Flutter desktop application</summary>
  <description>
    <p>$displayName - Built with Flutter.</p>
  </description>
  <launchable type="desktop-id">$applicationId.desktop</launchable>
  <icon type="stock">$applicationId</icon>
  <provides>
    <binary>$execName</binary>
  </provides>
  <categories>
    <category>Utility</category>
  </categories>
  <releases>
    <release version="$version"/>
  </releases>
  <pkgname>$debPackageName</pkgname>
</component>
''';
    final metainfoFile =
        File('${metainfoDir.path}/$applicationId.metainfo.xml'.normalizePath)
          ..createSync(recursive: true)
          ..writeAsStringSync(metainfoContent);
    await Process.run("chmod", ["0644", metainfoFile.path]);

    // The Description first line is the "title" apt/dpkg tools display next to
    // the package name, so lead with the human-readable display name.
    final controlContent = '''Package: $debPackageName
Version: $version
Architecture: $arch
Maintainer: MrtNetwork <mrhaydari.t@gmail.com>
Description: $displayName
 $displayName is a desktop application built with Flutter.
Section: utils
Priority: optional
Installed-Size: 500000
Depends: libc6, libgtk-3-0, libstdc++6, libgcc-s1
''';
    File('${debian.path}/control'.normalizePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(controlContent);

    // postinst / postrm refresh the desktop database and icon cache so the app
    // appears in the menu and its icon renders immediately after install,
    // instead of only after the next logout/login. They also link the binary
    // into PATH. "|| true" keeps install non-fatal on minimal systems.
    final postinst = '''#!/bin/sh
set -e
ln -sf "/opt/$packageName/$execName" "/usr/local/bin/$execName" || true
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
exit 0
''';
    final postrm = '''#!/bin/sh
set -e
rm -f "/usr/local/bin/$execName" || true
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
exit 0
''';
    final postinstFile = File('${debian.path}/postinst'.normalizePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(postinst);
    final postrmFile = File('${debian.path}/postrm'.normalizePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(postrm);
    // Maintainer scripts must be executable or dpkg silently ignores them.
    await Process.run("chmod", ["0755", postinstFile.path, postrmFile.path]);

    final result = await Process.run(
        "dpkg-deb", ["--build", "--root-owner-group", outDir.path]);
    if (result.exitCode != 0) {
      throw CompilerError('dpkg-deb failed: ${result.stderr}');
    }
  }
}

class NativeLiberaryAsset {
  final String url;
  final String hash;
  final String fileName;
  const NativeLiberaryAsset(
      {required this.url, required this.hash, required this.fileName});
}

/// ---------------------------------------------------------------------------
/// Rust source: a GitHub (or any git) repo, cached locally and kept in sync
/// by commit sha instead of a hand-picked local directory.
/// ---------------------------------------------------------------------------
class NativeLibraryConfig {
  NativeLibraryConfig({
    required this.repository,
    required this.gitUrl,
    this.linker,
    this.asset,
    this.branch = 'main',
    String? libName,
  }) : libName = libName ?? repository.name;

  /// Short id, also used as the cache-folder name and (by default) the
  /// crate's lib name and the wasm output sub-folder under web_scripts.
  final RustRepository repository;
  final String gitUrl;
  final String branch;
  final NativeLiberaryAsset? asset;

  /// The compiled artifact's base name, if different from [name] (e.g. your
  /// Cargo.toml sets `[lib] name = "..."` to something else).
  final String libName;

  final String? linker;

  Directory get cacheDir => switch (repository) {
        RustRepository.zk ||
        RustRepository.netSdk =>
          Directory('.rust_cache/${repository.name}'.normalizePath),
        RustRepository.cryptoC ||
        RustRepository.sqllite =>
          Directory('.c_cache/${repository.name}'.normalizePath),
      };

  String outFileName(RustArtifactKind kind) => switch (kind) {
        RustArtifactKind.sharedObject => 'lib$libName.so',
        RustArtifactKind.dylib => '$libName.dylib',
        RustArtifactKind.dll => 'lib$libName.dll',
        RustArtifactKind.wasm => '$libName.wasm',
        RustArtifactKind.staticLib => '$libName.a',
      };
}

/// Clones/updates a git repo into a local cache, skipping the network
/// entirely when the cached commit already matches the remote HEAD -
/// "keep latest commit if it exists, otherwise download".
class GitSourceManager {
  static Future<String> _remoteHeadCommit(String gitUrl, String branch) async {
    final result =
        await Process.run('git', ['ls-remote', gitUrl, 'refs/heads/$branch']);
    if (result.exitCode != 0) {
      throw CompilerError(
          'git ls-remote failed for $gitUrl ($branch): ${result.stderr}');
    }
    final line = (result.stdout as String).trim();
    if (line.isEmpty) {
      throw CompilerError('Branch "$branch" not found on $gitUrl');
    }
    return line.split(RegExp(r'\s+')).first;
  }

  static Future<String?> _localCommit(Directory dir) async {
    if (!Directory('${dir.path}/.git'.normalizePath).existsSync()) return null;
    final result = await Process.run('git', ['rev-parse', 'HEAD'],
        workingDirectory: dir.path);
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim();
  }

  /// Ensures [dir] holds an up-to-date checkout of [gitUrl]@[branch].
  /// Returns the commit sha that ends up checked out.
  static Future<String> sync({
    required String gitUrl,
    required String branch,
    required Directory dir,
  }) async {
    final remoteSha = await _remoteHeadCommit(gitUrl, branch);
    final localSha = await _localCommit(dir);
    if (localSha == remoteSha) {
      Log.success(
          '${dir.path}: cache up to date (${remoteSha.substring(0, 7)})');
      return remoteSha;
    }

    if (localSha == null) {
      Log.info('Cloning $gitUrl ($branch) -> ${dir.path} ...');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.parent.createSync(recursive: true);
      await ProcessRunner.run(
        'git',
        ['clone', '--branch', branch, '--single-branch', gitUrl, dir.path],
      );
    } else {
      Log.info(
        'Updating ${dir.path}: ${localSha.substring(0, 7)} -> ${remoteSha.substring(0, 7)}',
      );
      await ProcessRunner.run('git', ['fetch', 'origin', branch],
          workingDirectory: dir.path);
      await ProcessRunner.run(
        'git',
        ['reset', '--hard', 'origin/$branch'],
        workingDirectory: dir.path,
      );
    }
    return remoteSha;
  }

  static Future<String> syncAsset({
    required NativeLiberaryAsset asset,
    required Directory dir,
  }) async {
    await downloadAndExtract(asset: asset, output: dir);
    return dir.path;
  }

  static Future<File> getOrDownloadZipAssets({
    required NativeLiberaryAsset asset,
    required Directory output,
  }) async {
    final tempZip = File("${output.path}/${asset.fileName}".normalizePath);
    if (tempZip.existsSync()) {
      final bytes = tempZip.readAsBytesSync().immutable;
      final sha = BytesUtils.toHexString(QuickCrypto.sha256Hash(bytes));
      if (sha == asset.hash) {
        output.deleteSync(recursive: true);
        tempZip.createSync(recursive: true);
        tempZip.writeAsBytesSync(bytes);
        return tempZip;
      }
    }
    if (output.existsSync()) {
      output.deleteSync();
    }
    tempZip.createSync(recursive: true);
    final response = await http.get(Uri.parse(asset.url));
    if (response.statusCode != 200) {
      throw CompilerError(
        'Download failed: ${response.statusCode}',
      );
    }
    final sha =
        BytesUtils.toHexString(QuickCrypto.sha256Hash(response.bodyBytes));
    if (sha != asset.hash) {
      throw CompilerError(
        'Mismatch hash: ${response.statusCode}',
      );
    }
    tempZip.writeAsBytesSync(response.bodyBytes);
    return tempZip;
  }

  static Future<void> downloadAndExtract({
    required NativeLiberaryAsset asset,
    required Directory output,
  }) async {
    final tempZip = await getOrDownloadZipAssets(asset: asset, output: output);
    final archive = ZipDecoder().decodeBytes(
      tempZip.readAsBytesSync(),
    );
    for (final file in archive) {
      final filename = "${output.path}/${file.name}".normalizePath;
      if (file.isFile) {
        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filename).create(recursive: true);
      }
    }
  }
}

/// The kind of compiled artifact `cargo build` produces, per target OS -
/// determines the expected filename under `target/<triple>/<mode>/`.
enum RustArtifactKind { sharedObject, dylib, dll, wasm, staticLib }

enum RustRepository {
  zk("zk"),
  netSdk("net_sdk"),
  cryptoC("crypto_c"),
  sqllite("sqlite3mc");

  final String name;
  const RustRepository(this.name);

  /// Rust crates are compiled with cargo; C libraries are compiled with a
  /// C toolchain (see [CBuilder]).
  bool get isRust => this == RustRepository.zk || this == RustRepository.netSdk;
  bool get isC => !isRust;

  String get gitUrl => switch (this) {
        RustRepository.zk => BuildConfig.zkGitUrl,
        RustRepository.netSdk => BuildConfig.netSdkGitUrl,
        RustRepository.cryptoC => BuildConfig.cryptoCGitUrl,
        RustRepository.sqllite => BuildConfig.sqlite3,
      };
}

/// ---------------------------------------------------------------------------
/// C toolchain resolution
/// ---------------------------------------------------------------------------
/// How a compiler's flags/outputs are spelled. `gnu` covers gcc, clang and
/// plain `cc`; `msvc` covers `cl.exe`.
enum CCompilerFlavor { gnu, msvc }

/// A resolved, runnable C compiler for one specific target.
class ResolvedCCompiler {
  const ResolvedCCompiler({
    required this.exe,
    required this.flavor,
    this.targetArgs = const [],
  });

  /// The compiler executable (name on PATH, or absolute path for the NDK).
  final String exe;
  final CCompilerFlavor flavor;

  /// Args that select the target (e.g. `--target=...` for clang cross builds
  /// or `-arch ...` on Apple platforms). Empty for a native compiler.
  final List<String> targetArgs;

  bool get clang => exe == "clang";
}

/// One candidate the resolver probes, in priority order.
class _CCandidate {
  const _CCandidate(this.exe, this.flavor, [this.targetArgs = const []]);
  final String exe;
  final CCompilerFlavor flavor;
  final List<String> targetArgs;
}

/// Picks the first working C compiler for a target, honouring the
/// `gcc -> clang -> cc` preference the project asked for. Results are cached
/// per target so we only probe once.
class CToolchainResolver {
  static final Map<String, ResolvedCCompiler> _cache = {};

  /// True when [exe] can be launched at all. We deliberately don't rely on a
  /// `--version` exit code (cl/gcc behave differently with no input): a
  /// missing binary throws [ProcessException], anything else means it exists.
  static Future<bool> _exists(String exe) async {
    try {
      await Process.run(exe, const []);
      return true;
    } on ProcessException {
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<ResolvedCCompiler> resolve(
    String cacheKey,
    List<_CCandidate> candidates,
  ) async {
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final tried = <String>[];
    for (final c in candidates) {
      tried.add(c.exe);
      if (await _exists(c.exe)) {
        final resolved = ResolvedCCompiler(
          exe: c.exe,
          flavor: c.flavor,
          targetArgs: c.targetArgs,
        );
        Log.success(
          'C toolchain [$cacheKey]: ${([c.exe, ...c.targetArgs]).join(' ')}',
        );
        _cache[cacheKey] = resolved;
        return resolved;
      }
    }

    throw CompilerError(
      'No working C compiler found for "$cacheKey".\n'
      'Tried (in order): ${tried.join(', ')}.\n'
      'Install one of them (gcc, clang or cc), or pass '
      '--no-crypto-c / --no-sqlite3 to skip the native C libraries.',
    );
  }

  // -- Candidate lists per platform (gcc -> clang -> cc) --------------------

  /// Linux cross/native compilers for [arch] ("aarch64" or "x86_64").
  static List<_CCandidate> linux(String arch) {
    final triple = '$arch-linux-gnu';
    return [
      _CCandidate('$triple-gcc', CCompilerFlavor.gnu),
      _CCandidate('clang', CCompilerFlavor.gnu, ['--target=$triple']),
      _CCandidate('$triple-cc', CCompilerFlavor.gnu),
      // Native fall-backs (only correct when host arch == target arch).
      _CCandidate('gcc', CCompilerFlavor.gnu),
      _CCandidate('cc', CCompilerFlavor.gnu),
    ];
  }

  /// macOS compilers for [arch] ("arm64" or "x86_64"). `gcc` is an alias for
  /// clang on macOS, so all three accept `-arch`.
  static List<_CCandidate> macos(String arch) => [
        _CCandidate('gcc', CCompilerFlavor.gnu, ['-arch', arch]),
        _CCandidate('clang', CCompilerFlavor.gnu, ['-arch', arch]),
        _CCandidate('cc', CCompilerFlavor.gnu, ['-arch', arch]),
      ];

  /// Windows compilers: prefer a GNU-style toolchain (mingw gcc / clang / cc),
  /// then fall back to MSVC `cl`.
  static List<_CCandidate> windows() => const [
        _CCandidate('gcc', CCompilerFlavor.gnu),
        _CCandidate('clang', CCompilerFlavor.gnu),
        _CCandidate('cc', CCompilerFlavor.gnu),
        _CCandidate('cl', CCompilerFlavor.msvc),
      ];

  /// Android compilers come from the NDK's bundled clang. There is no gcc in
  /// modern NDKs, so the "fallback" is a standalone clang targeting the ABI.
  static List<_CCandidate> android(String abi, int api) {
    final triple = _androidClangTriple(abi, api);
    final ndk = androidNdkHome();
    final list = <_CCandidate>[];
    if (ndk != null) {
      final ext = Platform.isWindows ? '.cmd' : '';
      final clang =
          '$ndk/toolchains/llvm/prebuilt/${_ndkHostTag()}/bin/$triple-clang$ext'
              .normalizePath;
      list.add(_CCandidate(clang, CCompilerFlavor.gnu));
    }
    // Last resort: a system clang that knows the target triple. Needs a
    // sysroot to link successfully, but is offered so the build fails loudly
    // rather than silently doing nothing.
    list.add(_CCandidate('clang', CCompilerFlavor.gnu, ['--target=$triple']));
    return list;
  }

  static String? androidNdkHome() =>
      Platform.environment['ANDROID_NDK_HOME'] ??
      Platform.environment['ANDROID_NDK_ROOT'] ??
      Platform.environment['NDK_HOME'];

  static String _ndkHostTag() {
    if (Platform.isMacOS) return 'darwin-x86_64';
    if (Platform.isWindows) return 'windows-x86_64';
    return 'linux-x86_64';
  }

  static String _androidClangTriple(String abi, int api) => switch (abi) {
        'arm64-v8a' => 'aarch64-linux-android$api',
        'armeabi-v7a' => 'armv7a-linux-androideabi$api',
        'x86_64' => 'x86_64-linux-android$api',
        'x86' => throw CompilerError('Unsuported Android ABI: "$abi"'),
        _ => throw CompilerError('Unknown Android ABI: "$abi"'),
      };
}

enum Target {
  android,
  linux,
  windows,
  macos,
  ios,
  web,
  extension;
}

/// ---------------------------------------------------------------------------
/// C library builder (crypto_c, sqlite3mc) - cross-platform.
/// ---------------------------------------------------------------------------
/// Compiles the plain-C dependencies for every target Flutter ships to. The
/// compiler for each target is resolved via [CToolchainResolver] with the
/// gcc -> clang -> cc fallback, so the same script works on a dev laptop or a
/// CI image regardless of which toolchain happens to be installed.
class CBuilder {
  // -- Per-library source sets ----------------------------------------------

  static const List<String> _cryptoSources = [
    'src/fe.c',
    'src/ge.c',
    'src/keccak.c',
    'src/sc.c',
    'src/sha512.c',
    'src/on_chain_crypto.c',
  ];
  static const List<String> _cryptoDefines = <String>[];

  static const List<String> _sqliteSources = ['sqlite3mc_amalgamation.c'];
  // Add e.g. 'SQLITE_ENABLE_FTS5=1' here if your app needs extra features.
  static const List<String> _sqliteDefines = <String>[];

  static ({List<String> sources, List<String> defines}) _sourcesFor(
    RustRepository repo,
  ) {
    switch (repo) {
      case RustRepository.cryptoC:
        return (
          sources: _cryptoSources.map((e) => e.normalizePath).toList(),
          defines: _cryptoDefines
        );
      case RustRepository.sqllite:
        return (sources: _sqliteSources, defines: _sqliteDefines);
      default:
        throw CompilerError('${repo.name} is not a C library');
    }
  }

  /// Extra, compiler-specific warning flags (crypto is built -Wall -Werror).
  static List<String> _extraFlags(
      RustRepository repo, ResolvedCCompiler flavor, Target target) {
    List<String> args = [];
    if (target != Target.windows) {
      args.add("-fPIC");
    }
    if (flavor.flavor == CCompilerFlavor.gnu &&
        repo == RustRepository.cryptoC) {
      args.add("-DBUILDING_DL");
    }
    if (flavor.flavor == CCompilerFlavor.gnu &&
        flavor.clang &&
        repo == RustRepository.sqllite) {
      if (target == Target.windows) {
        args.add("-DSQLITE_API=__declspec(dllexport)");
      }
      args.add("-D_CRT_SECURE_NO_WARNINGS");
    }
    return args;
  }

  static Future<Directory> _syncedSource(NativeLibraryConfig repo) async {
    final dir = repo.cacheDir;
    final asset = repo.asset;
    if (asset != null) {
      await GitSourceManager.syncAsset(asset: asset, dir: dir);
    } else {
      final sha = await GitSourceManager.sync(
          gitUrl: repo.gitUrl, branch: repo.branch, dir: dir);
      Log.info(
          '${repo.repository.name}: building commit ${sha.substring(0, 7)}');
    }
    return dir;
  }

  // -- Generic single-artifact builders -------------------------------------

  /// Builds one shared library (.so / .dll) for [outPathRel] (relative to the
  /// source [dir]) using the resolved [cc]. Returns the absolute output path.
  static Future<String> _buildShared({
    required ResolvedCCompiler cc,
    required Directory dir,
    required RustRepository repo,
    required String outPathRel,
    required bool release,
    required Target target,
  }) async {
    final data = _sourcesFor(repo);
    Directory('${dir.path}/${FsUtils.dirOf(outPathRel)}'.normalizePath)
        .createSync(recursive: true);
    print("path ${'${dir.path}/${FsUtils.dirOf(outPathRel)}'.normalizePath}");
    final List<String> args;
    if (cc.flavor == CCompilerFlavor.msvc) {
      args = [
        ...cc.targetArgs,
        release ? '/O2' : '/Od',
        '/LD',
        for (final d in data.defines) '/D$d',
        ...data.sources,
        '/Fe:$outPathRel',
      ];
    } else {
      args = [
        ...cc.targetArgs,
        release ? '-O2' : '-O0',
        ..._extraFlags(repo, cc, target),
        for (final d in data.defines) '-D$d',
        ...data.sources,
        '-shared',
        '-o',
        outPathRel
      ];
    }
    print("out $args");
    await ProcessRunner.run(cc.exe, args, workingDirectory: dir.path);
    return '${dir.path}/$outPathRel'.normalizePath;
  }

  /// macOS dylib build (uses -dynamiclib + an @rpath install name so it can be
  /// embedded in the app bundle's Frameworks folder).
  static Future<String> _buildMacDylib({
    required ResolvedCCompiler cc,
    required Directory dir,
    required RustRepository repo,
    required String outPathRel,
    required String installName,
    required bool release,
  }) async {
    final data = _sourcesFor(repo);
    Directory('${dir.path}/${FsUtils.dirOf(outPathRel)}'.normalizePath)
        .createSync(recursive: true);
    final args = [
      ...cc.targetArgs,
      release ? '-O2' : '-O0',
      ..._extraFlags(repo, cc, Target.macos),
      for (final d in data.defines) '-D$d',
      ...data.sources,
      '-dynamiclib',
      '-install_name',
      installName,
      '-o',
      outPathRel,
    ];
    await ProcessRunner.run(cc.exe, args, workingDirectory: dir.path);
    return '${dir.path}/$outPathRel';
  }

  // -- Platform entry points ------------------------------------------------

  /// Linux: build arm64 + x86_64 shared objects and publish them under
  /// `<outputDir>/arm64/` and `<outputDir>/x86_64/`.
  static Future<void> buildForLinux({
    required NativeLibraryConfig repo,
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    final fileName = repo.outFileName(RustArtifactKind.sharedObject);

    final armCc = await CToolchainResolver.resolve(
      'linux-aarch64',
      CToolchainResolver.linux('aarch64'),
    );
    final intelCc = await CToolchainResolver.resolve(
      'linux-x86_64',
      CToolchainResolver.linux('x86_64'),
    );

    final armOut = await _buildShared(
      cc: armCc,
      dir: dir,
      target: Target.linux,
      repo: repo.repository,
      outPathRel: 'out/linux-arm64/$fileName'.normalizePath,
      release: release,
    );
    final intelOut = await _buildShared(
      cc: intelCc,
      dir: dir,
      repo: repo.repository,
      target: Target.linux,
      outPathRel: 'out/linux-x86_64/$fileName'.normalizePath,
      release: release,
    );

    FsUtils.publishFile(
      source: armOut,
      destination: '${outputDir.path}/arm64/$fileName'.normalizePath,
      name: repo.repository.name,
    );
    FsUtils.publishFile(
      source: intelOut,
      destination: '${outputDir.path}/x86_64/$fileName'.normalizePath,
      name: repo.repository.name,
    );
  }

  /// Android: one `lib<name>.so` per ABI, dropped straight into
  /// `jniLibsDir/<abi>/` where Gradle already expects them.
  static Future<void> buildForAndroid({
    required NativeLibraryConfig repo,
    required List<String> abis,
    required Directory jniLibsDir,
    required int api,
    bool release = true,
  }) async {
    if (CToolchainResolver.androidNdkHome() == null) {
      Log.info(
        'ANDROID_NDK_HOME/ANDROID_NDK_ROOT not set; falling back to a system '
        'clang for the C libraries. Set the NDK path for reliable builds.',
      );
    }
    final dir = await _syncedSource(repo);
    final soName = 'lib${repo.libName}.so';

    for (final abi in abis) {
      final cc = await CToolchainResolver.resolve(
        'android-$abi',
        CToolchainResolver.android(abi, api),
      );
      final out = await _buildShared(
        cc: cc,
        dir: dir,
        repo: repo.repository,
        target: Target.android,
        outPathRel: 'out/android-$abi/$soName'.normalizePath,
        release: release,
      );
      final destDir = Directory('${jniLibsDir.path}/$abi'.normalizePath)
        ..createSync(recursive: true);
      FsUtils.publishFile(
        source: out,
        destination:
            '${destDir.path}/${repo.outFileName(RustArtifactKind.sharedObject)}'
                .normalizePath,
        name: '${repo.repository.name} ($abi)',
      );
    }
  }

  /// macOS: build both slices and merge into one universal dylib via `lipo`.
  static Future<void> buildForMacos({
    required NativeLibraryConfig repo,
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    final dylib = 'lib${repo.libName}.dylib';

    final armCc = await CToolchainResolver.resolve(
      'macos-arm64',
      CToolchainResolver.macos('arm64'),
    );
    final intelCc = await CToolchainResolver.resolve(
      'macos-x86_64',
      CToolchainResolver.macos('x86_64'),
    );

    final armOut = await _buildMacDylib(
      cc: armCc,
      dir: dir,
      repo: repo.repository,
      outPathRel: 'out/macos-arm64/$dylib'.normalizePath,
      installName: '@rpath/$dylib',
      release: release,
    );
    final intelOut = await _buildMacDylib(
      cc: intelCc,
      dir: dir,
      repo: repo.repository,
      outPathRel: 'out/macos-x86_64/$dylib',
      installName: '@rpath/$dylib',
      release: release,
    );

    outputDir.createSync(recursive: true);
    final outPath = '${outputDir.path}/$dylib'.normalizePath;
    await ProcessRunner.run(
        'lipo', ['-create', armOut, intelOut, '-output', outPath]);
    Log.success('${repo.repository.name} (universal) -> $outPath');
  }

  /// Windows: build a single x64 DLL and copy it next to the exe location.
  static Future<void> buildForWindows({
    required NativeLibraryConfig repo,
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    final dll = repo.outFileName(RustArtifactKind.dll);
    final cc = await CToolchainResolver.resolve(
      'windows-x64',
      CToolchainResolver.windows(),
    );
    print("come here!");
    final out = await _buildShared(
      cc: cc,
      dir: dir,
      target: Target.windows,
      repo: repo.repository,
      outPathRel: 'out/windows-x64/$dll'.normalizePath,
      release: release,
    );
    outputDir.createSync(recursive: true);
    FsUtils.publishFile(
      source: out,
      destination: '${outputDir.path}/$dll'.normalizePath,
      name: repo.repository.name,
    );
  }

  /// iOS: build a static archive for device + simulator and bundle them into
  /// a `<name>.xcframework` under `<outputDir>/ios/`.
  static Future<void> buildForIos({
    required NativeLibraryConfig repo,
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);

    final deviceLib = await _iosStatic(
      dir: dir,
      repo: repo,
      sdk: 'iphoneos',
      archs: const ['arm64'],
      tag: 'device',
      release: release,
    );
    final simLib = await _iosStatic(
      dir: dir,
      repo: repo,
      sdk: 'iphonesimulator',
      archs: const ['arm64', 'x86_64'],
      tag: 'sim',
      release: release,
    );

    final out = Directory('${outputDir.path}/ios'.normalizePath)
      ..createSync(recursive: true);
    final xc = '${out.path}/${repo.libName}.xcframework'.normalizePath;
    if (Directory(xc).existsSync()) Directory(xc).deleteSync(recursive: true);

    await ProcessRunner.run('xcodebuild', [
      '-create-xcframework',
      '-library',
      deviceLib,
      '-library',
      simLib,
      '-output',
      xc,
    ]);
    Log.success('${repo.repository.name} -> $xc');
  }

  /// Compiles the C sources into a (possibly fat) static archive for one iOS
  /// SDK using `xcrun clang` + `ar`. Returns the absolute `.a` path.
  static Future<String> _iosStatic({
    required Directory dir,
    required NativeLibraryConfig repo,
    required String sdk,
    required List<String> archs,
    required String tag,
    required bool release,
  }) async {
    final sdkPathRes =
        await Process.run('xcrun', ['--sdk', sdk, '--show-sdk-path']);
    if (sdkPathRes.exitCode != 0) {
      throw CompilerError(
          'xcrun --sdk $sdk --show-sdk-path failed: ${sdkPathRes.stderr}');
    }
    final sysroot = (sdkPathRes.stdout as String).trim();
    final minFlag = sdk == 'iphonesimulator'
        ? '-mios-simulator-version-min=${BuildConfig.iosDeploymentTarget}'
        : '-miphoneos-version-min=${BuildConfig.iosDeploymentTarget}';

    final data = _sourcesFor(repo.repository);
    final outRel = 'out/ios-$tag';
    final objDir = Directory('${dir.path}/$outRel/obj'.normalizePath)
      ..createSync(recursive: true);
    final archArgs = [
      for (final a in archs) ...['-arch', a]
    ];

    final objects = <String>[];
    for (final src in data.sources) {
      final objPath = '${objDir.path}/${src.replaceAll('/', '_')}.o';
      await ProcessRunner.run(
        'xcrun',
        [
          '--sdk',
          sdk,
          'clang',
          ...archArgs,
          '-isysroot',
          sysroot,
          minFlag,
          release ? '-O2' : '-O0',
          ..._extraFlags(
              repo.repository,
              ResolvedCCompiler(exe: '', flavor: CCompilerFlavor.gnu),
              Target.ios),
          for (final d in data.defines) '-D$d',
          '-c',
          src,
          '-o',
          objPath,
        ],
        workingDirectory: dir.path,
      );
      objects.add(objPath);
    }

    final libPath = '${dir.path}/$outRel/lib${repo.libName}.a'.normalizePath;
    FsUtils.deleteFile(libPath);
    await ProcessRunner.run('xcrun', ['ar', 'rcs', libPath, ...objects]);
    return libPath;
  }
}

/// Builds a [NativeLibraryConfig] for whichever platform is being targeted: wasm
/// for web/extension, the matching native target triple otherwise. Sources
/// are fetched/cached via [GitSourceManager] instead of read from a fixed
/// local path.
class RustBuilder {
  static bool? _toolchainAvailable;

  /// Fails fast with a clear message if `cargo` isn't on PATH, rather than
  /// letting a rust build silently do nothing or fail deep in a subprocess.
  static Future<void> ensureToolchain() async {
    _toolchainAvailable ??= await _checkCargo();
    if (_toolchainAvailable != true) {
      throw CompilerError(
        'Rust build requested but no working "cargo" was found on PATH.\n'
        'Install it via https://rustup.rs, or pass --no-rust to skip native builds.',
      );
    }
  }

  static Future<bool> _checkCargo() async {
    try {
      final result = await Process.run('cargo', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Best-effort: toolchains not managed by rustup don't support this, so a
  /// failure here is just a warning rather than a hard build failure.
  static Future<void> _ensureRustupTarget(String triple) async {
    try {
      final result = await Process.run('rustup', ['target', 'add', triple]);
      if (result.exitCode != 0) {
        Log.info('Could not "rustup target add $triple" (continuing anyway).');
      }
    } catch (_) {
      Log.info(
          'rustup not found; assuming target "$triple" is already installed.');
    }
  }

  static Future<Directory> _syncedSource(NativeLibraryConfig repo) async {
    final dir = repo.cacheDir;

    final sha = await GitSourceManager.sync(
        gitUrl: repo.gitUrl, branch: repo.branch, dir: dir);
    Log.info('${repo.repository.name}: building commit ${sha.substring(0, 7)}');
    return dir;
  }

  static Future<void> _cargoBuild(
    Directory dir,
    String triple, {
    required bool release,
  }) async {
    await _ensureRustupTarget(triple);
    final environment = Map<String, String>.fromEntries(
        Platform.environment.entries.where((e) =>
            e.key.startsWith("CARGO_TARGET") || e.key.startsWith("CC_")));
    await ProcessRunner.run(
        'cargo',
        [
          'build',
          '--target',
          triple,
          if (release) '--release',
        ],
        workingDirectory: dir.path,
        environment: environment);
  }

  static String _artifactPath({
    required Directory sourceDir,
    required String triple,
    required String libName,
    required bool release,
    required RustArtifactKind kind,
  }) {
    final mode = release ? 'release' : 'debug';
    final fileName = switch (kind) {
      RustArtifactKind.sharedObject => 'lib$libName.so',
      RustArtifactKind.dylib => 'lib$libName.dylib',
      RustArtifactKind.dll => '$libName.dll',
      RustArtifactKind.wasm => '$libName.wasm',
      RustArtifactKind.staticLib => 'lib$libName.a',
    };
    final out = 'target/$triple/$mode';
    Directory('${sourceDir.path}/$out'.normalizePath)
        .createSync(recursive: true);
    return "$out/$fileName";
  }

  static String _androidTriple(String abi) => switch (abi) {
        'arm64-v8a' => 'aarch64-linux-android',
        'armeabi-v7a' => 'armv7-linux-androideabi',
        'x86_64' => 'x86_64-linux-android',
        'x86' => throw CompilerError('Unsuported Android ABI: "$abi"'),
        _ => throw CompilerError('Unknown Android ABI: "$abi"'),
      };

  /// web/extension target: wasm32-unknown-unknown, then wasm-bindgen -
  /// same output layout as before (assets/web_scripts/<'name>/...).
  static Future<void> buildForWeb(NativeLibraryConfig repo,
      {bool release = true}) async {
    final dir = await _syncedSource(repo);
    const triple = 'wasm32-unknown-unknown';
    await _cargoBuild(dir, triple, release: release);
    final wasmPath = _artifactPath(
      sourceDir: dir,
      triple: triple,
      libName: repo.libName,
      release: release,
      kind: RustArtifactKind.wasm,
    );
    await ProcessRunner.run(
      'wasm-bindgen',
      [
        wasmPath,
        '--out-dir',
        '${Directory.current.path}/${BuildConfig.webScriptAssetsDir}/${repo.repository.name}'
            .normalizePath,
        '--target',
        'web',
      ],
      workingDirectory: dir.path,
    );
  }

  /// android target: one .so per ABI, copied straight into
  /// `jniLibsDir/<abi>/lib<name>.so` where Gradle already expects them.
  static Future<void> buildForAndroid(
    NativeLibraryConfig repo, {
    required List<String> abis,
    required Directory jniLibsDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    for (final abi in abis) {
      final triple = _androidTriple(abi);
      await _cargoBuild(dir, triple, release: release);
      final path = _artifactPath(
        sourceDir: dir,
        triple: triple,
        libName: repo.libName,
        release: release,
        kind: RustArtifactKind.sharedObject,
      );
      // final source = File(
      //   ,
      // );
      // assert(source.existsSync(), "source file not found. ${source.path}");
      Directory('${jniLibsDir.path}/$abi'.normalizePath)
          .createSync(recursive: true);
      final destinationPath =
          "${jniLibsDir.path}/$abi/${repo.outFileName(RustArtifactKind.sharedObject)}"
              .normalizePath;
      FsUtils.publishFile(
          source: "${dir.path}/$path".normalizePath,
          destination: destinationPath,
          name: repo.repository.name);

      // final destPath = '${destDir.path}/${source.uri.pathSegments.last}';
      // source.copySync(destPath);
      Log.success('${repo.repository.name} ($abi) -> $destinationPath');
    }
  }

  /// macOS target: build both Apple Silicon and Intel, merge into one
  /// universal dylib via `lipo`.
  static Future<void> buildForMacos(
    NativeLibraryConfig repo, {
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    const arm = 'aarch64-apple-darwin';
    const intel = 'x86_64-apple-darwin';
    await _cargoBuild(dir, arm, release: release);
    await _cargoBuild(dir, intel, release: release);

    final armLib = _artifactPath(
        sourceDir: dir,
        triple: arm,
        libName: repo.libName,
        release: release,
        kind: RustArtifactKind.dylib);
    final intelLib = _artifactPath(
      sourceDir: dir,
      triple: intel,
      libName: repo.libName,
      release: release,
      kind: RustArtifactKind.dylib,
    );

    outputDir.createSync(recursive: true);
    final outPath = '${outputDir.path}/lib${repo.libName}.dylib'.normalizePath;
    await ProcessRunner.run('lipo', [
      '-create',
      '${dir.path}/$armLib'.normalizePath,
      '${dir.path}/$intelLib'.normalizePath,
      '-output',
      outPath,
    ]);
    Log.success('${repo.repository.name} (universal) -> $outPath');
  }

  /// windows target: build for the host MSVC toolchain and copy the .dll -
  /// Windows loads DLLs from the executable's own directory by default.
  static Future<void> buildForWindows(
    NativeLibraryConfig repo, {
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    const triple = 'x86_64-pc-windows-msvc';
    await _cargoBuild(dir, triple, release: release);
    final sourcePath = _artifactPath(
      sourceDir: dir,
      triple: triple,
      libName: repo.libName,
      release: release,
      kind: RustArtifactKind.dll,
    );
    // final source = File(
    //   "${dir.path}/$sourcePath".normalizePath
    // );
    outputDir.createSync(recursive: true);
    // final destPath = '${outputDir.path}/${source.uri.pathSegments.last}'.normalizePath;
    // source.copySync(destPath);
    // Log.success('${repo.repository.name} -> $destPath');
    FsUtils.publishFile(
        source: "${dir.path}/$sourcePath".normalizePath,
        destination:
            "${outputDir.path}/${repo.outFileName(RustArtifactKind.dll)}"
                .normalizePath,
        name: repo.repository.name);
  }

  /// linux target: build arm64 + x86_64 shared objects (optionally with custom
  /// cross-linkers) and publish them under `<outputDir>/arm64|x86_64/`.
  static Future<void> buildForLinux({
    required NativeLibraryConfig repo,
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    const arm = 'aarch64-unknown-linux-gnu';
    const intel = 'x86_64-unknown-linux-gnu';

    await _cargoBuild(dir, arm, release: release);
    await _cargoBuild(dir, intel, release: release);
    final armLib = _artifactPath(
        sourceDir: dir,
        triple: arm,
        libName: repo.libName,
        release: release,
        kind: RustArtifactKind.sharedObject);
    final intelLib = _artifactPath(
      sourceDir: dir,
      triple: intel,
      libName: repo.libName,
      release: release,
      kind: RustArtifactKind.sharedObject,
    );
    outputDir.createSync(recursive: true);
    FsUtils.publishFile(
        source: "${dir.path}/$armLib".normalizePath,
        destination:
            "${outputDir.path}/arm64/${repo.outFileName(RustArtifactKind.sharedObject)}"
                .normalizePath,
        name: repo.repository.name);
    FsUtils.publishFile(
        source: "${dir.path}/$intelLib".normalizePath,
        destination:
            "${outputDir.path}/x86_64/${repo.outFileName(RustArtifactKind.sharedObject)}"
                .normalizePath,
        name: repo.repository.name);
  }

  /// iOS target: build a device (arm64) static lib and a universal simulator
  /// (arm64 + x86_64) static lib, then bundle both into a `.xcframework`.
  ///
  /// Requires the crate to expose `crate-type = ["staticlib"]` (in addition to
  /// whatever else it builds) so cargo emits `lib<name>.a`.
  static Future<void> buildForIos(
    NativeLibraryConfig repo, {
    required Directory outputDir,
    bool release = true,
  }) async {
    final dir = await _syncedSource(repo);
    const device = 'aarch64-apple-ios';
    const simArm = 'aarch64-apple-ios-sim';
    const simX64 = 'x86_64-apple-ios';

    for (final triple in const [device, simArm, simX64]) {
      await _cargoBuild(dir, triple, release: release);
    }

    String artifact(String triple) =>
        '${dir.path}/${_artifactPath(sourceDir: dir, triple: triple, libName: repo.libName, release: release, kind: RustArtifactKind.staticLib)}'
            .normalizePath;

    final out = Directory('${outputDir.path}/ios'.normalizePath)
      ..createSync(recursive: true);

    // Simulator: lipo the two sim slices into one fat archive.
    final simFat = '${out.path}/lib${repo.libName}_sim.a'.normalizePath;
    FsUtils.deleteFile(simFat);
    await ProcessRunner.run('lipo', [
      '-create',
      artifact(simArm),
      artifact(simX64),
      '-output',
      simFat,
    ]);

    final xc = '${out.path}/${repo.libName}.xcframework'.normalizePath;
    if (Directory(xc).existsSync()) Directory(xc).deleteSync(recursive: true);
    await ProcessRunner.run('xcodebuild', [
      '-create-xcframework',
      '-library',
      artifact(device),
      '-library',
      simFat,
      '-output',
      xc,
    ]);
    Log.success('${repo.repository.name} -> $xc');
  }
}

/// ---------------------------------------------------------------------------
/// dart compile js/wasm
/// ---------------------------------------------------------------------------
class ScriptCompiler {
  /// Compiles a `.dart` entrypoint to a web script (js or wasm), writing the
  /// result under [BuildConfig.webScriptAssetsDir] unless [out] is given.
  /// Returns the path that was written.
  static Future<String> compile({
    required String scriptName,
    String directory = BuildConfig.jsScriptsDir,
    String? out,
    bool wasm = true,
    bool minify = true,
  }) async {
    final suffix = wasm ? 'wasm' : 'js';
    Log.info(
      'Compiling $directory/$scriptName.dart -> ${wasm ? 'WASM' : 'JS'} (minify: $minify)',
    );

    final outPath = out != null
        ? out.contains('.')
            ? out
            : '$out.$suffix'
        : BuildConfig.webScriptAsset('$scriptName.$suffix');

    await ProcessRunner.run('dart', [
      'compile',
      wasm ? 'wasm' : 'js',
      if (!wasm && minify) '-m',
      if (wasm && minify) '-O4',
      '-o',
      outPath,
      '$directory/$scriptName.dart'.normalizePath,
      '--no-source-maps',
    ]);

    // Clean up compiler side-artifacts we don't ship.
    final withoutExtension = outPath.substring(0, outPath.lastIndexOf('.'));
    FsUtils.deleteFile(
      wasm ? '$withoutExtension.support.js' : '$withoutExtension.js.deps',
    );

    return outPath;
  }
}

/// ---------------------------------------------------------------------------
/// Shared web-script build steps (used by both the web app and the extension)
/// ---------------------------------------------------------------------------
class WebScriptsBuilder {
  static Future<void> crypto({bool wasm = true, bool minify = true}) async {
    await ScriptCompiler.compile(
        scriptName: 'crypto', wasm: wasm, minify: minify);
    await ScriptCompiler.compile(
      scriptName: 'stream_crypto',
      wasm: wasm,
      minify: minify,
    );
  }

  static Future<void> worker({bool minify = true}) =>
      ScriptCompiler.compile(scriptName: 'worker', wasm: false, minify: minify);

  static Future<void> context({bool minify = true}) =>
      ScriptCompiler.compile(scriptName: 'context', wasm: true, minify: minify);

  // static Future<void> http({bool wasm = true, bool minify = true}) =>
  //     ScriptCompiler.compile(scriptName: 'http', wasm: wasm, minify: minify);

  /// Runs whichever of the shared script builds are enabled by [options].
  static Future<void> buildEnabled(BuildOptions options) async {
    if (options.rust) {
      await RustBuilder.ensureToolchain();
      for (final repo in [options.zkRepo].whereType<NativeLibraryConfig>()) {
        await RustBuilder.buildForWeb(repo, release: !options.debug);
      }
    }
    if (options.context) await context(minify: options.minify);
    if (options.worker) await worker(minify: options.minify);
    if (options.crypto) {
      await crypto(wasm: options.wasm, minify: options.minify);
    }
  }
}

/// ---------------------------------------------------------------------------
/// flutter build web / flutter build web --csp (for extensions)
/// ---------------------------------------------------------------------------
class FlutterWebCompiler {
  static Future<void> compileApp({
    bool wasm = true,
    bool minify = false,
    bool asExtension = false,
    String? baseHref,
    bool noCdn = false,
  }) async {
    await ProcessRunner.run('flutter', [
      'build',
      'web',
      if (wasm) '--wasm',
      minify ? '--release' : '--debug',
      if (asExtension) '--csp',
      if (noCdn) '--no-web-resources-cdn',
      if (!asExtension && baseHref != null) '--base-href=$baseHref',
    ]);

    if (asExtension && !noCdn) {
      await _rewriteCanvaskitUrl();
    }
  }

  /// Extensions can't reach Google's CDN, so the canvaskit URL baked into
  /// main.dart.js is rewritten to a local `/canvaskit/` path.
  static Future<void> _rewriteCanvaskitUrl() async {
    const pattern = r'https://www\.gstatic\.com/flutter-canvaskit/([a-f0-9]+)/';
    final file = File('${BuildConfig.buildWebDir}main.dart.js'.normalizePath);
    var data = await file.readAsString();

    final match = RegExp(pattern).firstMatch(data);
    if (match == null) {
      throw CompilerError('Failed to find canvaskit URL in ${file.path}');
    }
    final matched = match.group(0)!;
    data = data.replaceFirst(matched, '/canvaskit/');
    await file.writeAsString(data);
    Log.success('canvaskit URL rewritten (was: $matched)');
  }
}

/// ---------------------------------------------------------------------------
/// Options shared across build targets
/// ---------------------------------------------------------------------------
class BuildOptions {
  BuildOptions({
    this.debug = false,
    this.wasm = true,
    this.crypto = true,
    this.worker = true,
    this.rust = true,
    this.context = true,
    this.production = false,
    this.releaseLocation = BuildConfig.defaultReleaseLocation,
    this.zkRepo,
    this.netSdkRepo,
    this.androidAbis = const ['arm64-v8a', 'armeabi-v7a', 'x86_64'],
    this.androidApi = BuildConfig.defaultAndroidApi,
    this.noCodesign = true,
    this.webView = true,
    this.webViewWorker = true,
    this.cryptoC,
    this.sqlite3,
    Directory? jniLibsDir,
    Directory? macosLibDir,
    Directory? windowsLibDir,
    Directory? linuxLibDir,
    Directory? iosLibDir,
  })  : jniLibsDir = jniLibsDir ??
            Directory('android/app/src/main/jniLibs'.normalizePath),
        macosLibDir =
            macosLibDir ?? Directory('macos/Runner/NativeLibs'.normalizePath),
        windowsLibDir = windowsLibDir ?? Directory('windows'.normalizePath),
        linuxLibDir = linuxLibDir ?? Directory('linux'),
        iosLibDir =
            iosLibDir ?? Directory('ios/Runner/NativeLibs'.normalizePath);

  final bool debug;
  final bool wasm;
  final bool crypto;
  final bool worker;
  final bool rust;
  final bool context;
  final bool production;
  final bool webView;
  final bool webViewWorker;
  final String releaseLocation;

  /// Null when `rust` is false and no repo URL was needed/given.
  final NativeLibraryConfig? zkRepo;
  final NativeLibraryConfig? netSdkRepo;
  final NativeLibraryConfig? cryptoC;
  final NativeLibraryConfig? sqlite3;

  final List<String> androidAbis;
  final int androidApi;

  /// iOS only: pass `--no-codesign` to `flutter build ios` (default true for
  /// CI). Toggled off with the `--codesign` flag.
  final bool noCodesign;

  final Directory jniLibsDir;
  final Directory macosLibDir;
  final Directory windowsLibDir;
  final Directory linuxLibDir;
  final Directory iosLibDir;

  bool get minify => !debug;
}

/// ---------------------------------------------------------------------------
/// Plain web app build
/// ---------------------------------------------------------------------------
class WebAppBuilder {
  static Future<void> build(BuildOptions options) async {
    await WebScriptsBuilder.buildEnabled(options);
    _cleanExtensionOnlyFiles();
    _copyBrowserShell();
    await FlutterWebCompiler.compileApp(
        wasm: options.wasm,
        minify: options.minify,
        asExtension: false,
        baseHref: options.production ? BuildConfig.productionBaseHref : null,
        noCdn: true);

    final destination =
        Directory('${options.releaseLocation}web/'.normalizePath);
    FsUtils.copyDirectory(
      Directory(BuildConfig.buildWebDir.normalizePath),
      destination,
      cleanDestination: true,
    );
    Log.success('Web build copied to ${destination.absolute.path}');
  }

  static void _cleanExtensionOnlyFiles() {
    if (!Directory(BuildConfig.buildWebDir.normalizePath).existsSync()) return;
    const extensionOnlyFiles = [
      'tron_web.js',
      'content.js',
      'background.js',
      'page.js',
      'index.html',
      'side_panel.html',
      'iframe.html',
      'iframe_events.js',
    ];
    FsUtils.deleteFiles(
        extensionOnlyFiles.map((f) => '${BuildConfig.buildWebDir}$f'));
  }

  static void _copyBrowserShell() {
    final webDir = Directory(BuildConfig.webOutDir.normalizePath);
    if (webDir.existsSync()) webDir.deleteSync(recursive: true);
    webDir.createSync(recursive: true);
    FsUtils.copyDirectory(
        Directory(BuildConfig.browserSourceDir.normalizePath), webDir);
  }
}

/// ---------------------------------------------------------------------------
/// Browser extension build
/// ---------------------------------------------------------------------------
enum ExtensionTarget { chrome, firefox, opera, ie }

extension on ExtensionTarget {
  String get folderName => switch (this) {
        ExtensionTarget.chrome => 'chrome',
        ExtensionTarget.firefox => 'firefox',
        ExtensionTarget.opera => 'opera',
        ExtensionTarget.ie => 'internet_explorer',
      };
}

class WebviewScriptBuilder {
  static Future<void> buildWebview({bool minify = false}) async {
    await ScriptCompiler.compile(
      scriptName: 'webview',
      directory: 'js',
      out: '${BuildConfig.webviewSourceDir}script'.normalizePath,
      minify: minify,
      wasm: false,
    );
    final file = File("${BuildConfig.webviewSourceDir}script.js".normalizePath);
    file.copySync(BuildConfig.webViewAssets("script.js"));
  }

  static Future<void> buildWebviewPage(
      {bool minify = false, bool worker = true}) async {
    await ScriptCompiler.compile(
      scriptName: worker ? 'webview_page' : "webview_page_main",
      directory: 'js',
      out: '${BuildConfig.webviewSourceDir}script_page'.normalizePath,
      minify: minify,
      wasm: false,
    );
    final file =
        File("${BuildConfig.webviewSourceDir}script_page.js".normalizePath);
    file.copySync(BuildConfig.webViewAssets("script_page.js"));
  }
}

class ExtensionBuilder {
  static Future<void> build(
    BuildOptions options, {
    required ExtensionTarget target,
    bool buildPageScript = true,
    bool buildContentScript = true,
    bool buildBackgroundScript = true,
  }) async {
    await WebScriptsBuilder.buildEnabled(options);

    if (buildPageScript) await _buildPage(minify: options.minify);
    if (buildBackgroundScript) await _buildBackground(minify: options.minify);
    if (buildContentScript) await _buildContent(minify: options.minify);

    WebAppBuilder._cleanExtensionOnlyFiles();
    WebAppBuilder._copyBrowserShell();
    _assembleManifest(target);

    await FlutterWebCompiler.compileApp(
      wasm: options.wasm,
      minify: options.minify,
      asExtension: true,
      noCdn: true,
      baseHref: options.production ? BuildConfig.productionBaseHref : null,
    );

    final destination = Directory(
        '${options.releaseLocation}${target.folderName}/'.normalizePath);
    FsUtils.copyDirectory(
      Directory(BuildConfig.buildWebDir.normalizePath),
      destination,
      cleanDestination: true,
    );
    Log.success(
        'Extension (${target.folderName}) copied to ${destination.absolute.path}');
  }

  static Future<void> _buildPage({bool minify = false}) =>
      ScriptCompiler.compile(
        scriptName: 'page',
        directory: 'js',
        out: '${BuildConfig.extensionSourceDir}page'.normalizePath,
        minify: minify,
        wasm: false,
      );

  static Future<void> _buildBackground({bool minify = false}) async {
    await ScriptCompiler.compile(
      scriptName: 'background',
      directory: 'js/background'.normalizePath,
      out: '${BuildConfig.extensionSourceDir}background'.normalizePath,
      minify: minify,
      wasm: false,
    );
  }

  static Future<void> _buildContent({bool minify = false}) async {
    final compiledPath = await ScriptCompiler.compile(
      scriptName: 'content',
      directory: 'js',
      out: '${BuildConfig.extensionSourceDir}content'.normalizePath,
      minify: minify,
      wasm: false,
    );
    await _writeFirefoxContentScript(compiledPath, minify: minify);
  }

  /// Firefox's content-script sandbox doesn't expose `browser`/`cloneInto`/
  /// `Uint8Array` the same way; patch the compiled output so it works there.
  static Future<void> _writeFirefoxContentScript(
    String compiledPath, {
    required bool minify,
  }) async {
    final source = File(compiledPath.normalizePath);
    var data = source.readAsStringSync();

    if (minify) {
      const marker = '(function dartProgram(){';
      if (!data.contains(marker)) {
        throw CompilerError(
            'Unrecognized minified content script output (marker not found)');
      }
      data = data.replaceFirst(
        marker,
        '$marker'
        'if(self.browser === undefined){self.browser = browser;self.cloneInto = cloneInto; self.Uint8Array = Uint8Array;}',
      );
    } else {
      const marker = 'main() {';
      if (!data.contains(marker)) {
        throw CompilerError(
            'Unrecognized content script output (marker not found)');
      }
      data = data.replaceFirst(marker, '''    main() {
      if(self.browser === undefined){
        self.browser = browser
        self.cloneInto = cloneInto
        self.Uint8Array = Uint8Array;
      }''');
    }

    final firefoxFile = File(
        '${BuildConfig.extensionSourceDir}firefox_content.js'.normalizePath);
    if (firefoxFile.existsSync()) firefoxFile.deleteSync();
    firefoxFile.createSync(recursive: true);
    await firefoxFile.writeAsString(data);
  }

  /// Copies the right manifest + supporting html for [target] into `web/`.
  static void _assembleManifest(ExtensionTarget target) {
    void copyToWeb(String fileName, {String? outName}) {
      final file =
          File('${BuildConfig.extensionSourceDir}$fileName'.normalizePath);
      if (!file.existsSync()) {
        throw CompilerError('Required extension file not found: ${file.path}');
      }
      file.copySync(
          '${BuildConfig.webOutDir}/${outName ?? fileName}'.normalizePath);
    }

    copyToWeb('tron_web.js');
    copyToWeb('background.js');
    copyToWeb('page.js');
    copyToWeb('index.html');

    if (target == ExtensionTarget.chrome || target == ExtensionTarget.ie) {
      copyToWeb('content.js');
      copyToWeb('chrome_manifest.json', outName: 'manifest.json');
      copyToWeb('side_panel.html');
    } else if (target == ExtensionTarget.opera) {
      copyToWeb('content.js');
      copyToWeb('opera_manifest.json', outName: 'manifest.json');
      copyToWeb('side_panel.html');
    } else if (target == ExtensionTarget.firefox) {
      copyToWeb('firefox_content.js', outName: 'content.js');
      copyToWeb('side_panel.html');
      copyToWeb('iframe.html');
      copyToWeb('iframe_events.js');
      copyToWeb('mozila_manifest.json', outName: 'manifest.json');
    }
  }
}

/// ---------------------------------------------------------------------------
/// Native app builds (apk / macos / windows / linux / ios)
/// ---------------------------------------------------------------------------
/// Native libraries are split into two groups that are compiled by different
/// toolchains, then the matching `flutter build <platform>` is run:
///   * rust crates (zk, net_sdk)  -> [RustBuilder] via cargo
///   * C libraries (crypto_c, sqlite3mc) -> [CBuilder] via gcc/clang/cc
class NativeAppBuilder {
  static List<NativeLibraryConfig> _rustRepos(BuildOptions options) => [
        options.zkRepo,
        options.netSdkRepo,
      ].whereType<NativeLibraryConfig>().toList();

  static List<NativeLibraryConfig> _cRepos(BuildOptions options) => [
        options.sqlite3,
        options.cryptoC,
      ].whereType<NativeLibraryConfig>().toList();

  static Future<void> apk({
    required BuildOptions options,
    bool splitPerAbi = false,
  }) async {
    final rustRepos = _rustRepos(options);
    final cRepos = _cRepos(options);

    if (options.rust && rustRepos.isNotEmpty) {
      await RustBuilder.ensureToolchain();
      for (final repo in rustRepos) {
        await RustBuilder.buildForAndroid(
          repo,
          abis: options.androidAbis,
          jniLibsDir: options.jniLibsDir,
          release: !options.debug,
        );
      }
    }
    for (final repo in cRepos) {
      await CBuilder.buildForAndroid(
        repo: repo,
        abis: options.androidAbis,
        jniLibsDir: options.jniLibsDir,
        api: options.androidApi,
        release: !options.debug,
      );
    }

    if (options.webView) {
      await WebviewScriptBuilder.buildWebview(minify: !options.debug);
      await WebviewScriptBuilder.buildWebviewPage(
          minify: !options.debug, worker: options.webViewWorker);
    }

    await ProcessRunner.run('flutter', [
      'build',
      'apk',
      options.debug ? '--debug' : '--release',
      if (splitPerAbi) '--split-per-abi',
    ]);
    final source = Directory('build/app/outputs/flutter-apk'.normalizePath);
    final destination =
        Directory('${options.releaseLocation}android/'.normalizePath);
    FsUtils.copyDirectory(source, destination, cleanDestination: true);
    Log.success('APK(s) copied to ${destination.absolute.path}');
  }

  static Future<void> macos({required BuildOptions options}) async {
    final rustRepos = _rustRepos(options);
    final cRepos = _cRepos(options);

    if (options.rust && rustRepos.isNotEmpty) {
      await RustBuilder.ensureToolchain();
      for (final repo in rustRepos) {
        await RustBuilder.buildForMacos(
          repo,
          outputDir: options.macosLibDir,
          release: !options.debug,
        );
      }
    }
    for (final repo in cRepos) {
      await CBuilder.buildForMacos(
        repo: repo,
        outputDir: options.macosLibDir,
        release: !options.debug,
      );
    }
    if (rustRepos.isNotEmpty || cRepos.isNotEmpty) {
      Log.info(
        'Native libs written to ${options.macosLibDir.path} - make sure your '
        'Xcode target embeds/copies that folder (e.g. a "Copy Files" build '
        'phase into Frameworks) if it does not already.',
      );
    }

    await ProcessRunner.run('flutter', [
      'build',
      'macos',
      options.debug ? '--debug' : '--release',
    ]);
    final buildMode = options.debug ? 'Debug' : 'Release';
    final source =
        Directory('build/macos/Build/Products/$buildMode'.normalizePath);
    final destination =
        Directory('${options.releaseLocation}macos/'.normalizePath);
    FsUtils.copyDirectory(source, destination, cleanDestination: true);
    Log.success('macOS build copied to ${destination.absolute.path}');
  }

  static Future<void> windows({required BuildOptions options}) async {
    final rustRepos = _rustRepos(options);
    final cRepos = _cRepos(options);

    if (options.rust && rustRepos.isNotEmpty) {
      await RustBuilder.ensureToolchain();
      for (final repo in rustRepos) {
        await RustBuilder.buildForWindows(
          repo,
          outputDir: options.windowsLibDir,
          release: !options.debug,
        );
      }
    }
    for (final repo in cRepos) {
      await CBuilder.buildForWindows(
        repo: repo,
        outputDir: options.windowsLibDir,
        release: !options.debug,
      );
    }

    await ProcessRunner.run('flutter', [
      'build',
      'windows',
      options.debug ? '--debug' : '--release',
    ]);
    final buildMode = options.debug ? 'Debug' : 'Release';
    final source =
        Directory('build/windows/x64/runner/$buildMode'.normalizePath);
    final destination =
        Directory('${options.releaseLocation}windows/'.normalizePath);
    FsUtils.copyDirectory(source, destination, cleanDestination: true);
    // Windows loads DLLs from next to the exe, so make sure the compiled
    // native libs also end up in the shipped release folder.
    if (options.windowsLibDir.existsSync()) {
      FsUtils.copyDirectory(options.windowsLibDir, destination,
          cleanDestination: false);
    }
    Log.success('Windows build copied to ${destination.absolute.path}');
  }

  /// Builds the Linux app for BOTH x86_64 and aarch64 by default: the arch
  /// matching the current host is built natively, and the other one is built
  /// inside a QEMU-emulated Docker container of that architecture. Use
  /// --linux-arch=<'x86_64|arm64> to build a single target, or --no-docker to
  /// skip (instead of fail) foreign arches when Docker is unavailable.
  static Future<void> linux({
    required BuildOptions options,
    required Set<String> rawFlags,
  }) async {
    final requested = _valueOfFlag(rawFlags, '--linux-arch=');
    final noDocker = rawFlags.contains('--no-docker');
    final image = _valueOfFlag(rawFlags, '--docker-image=') ??
        DockerCrossBuilder.defaultImage;
    final List<LinuxArch> targets;
    if (requested != null) {
      final arch = LinuxArch.fromString(requested);
      if (arch == null) {
        throw CompilerError('Unknown --linux-arch value "$requested". '
            'Use x86_64 or arm64.');
      }
      targets = [arch];
    } else {
      // No arch detection games: always ship both.
      targets = LinuxArch.values;
    }

    final host = await LinuxArch.host();
    // Build the native arch first: it is fast and fails early on real
    // problems before the (slow) emulated build starts.
    final ordered = [...targets]
      ..sort((a, b) => (a == host ? 0 : 1).compareTo(b == host ? 0 : 1));
    for (final arch in ordered) {
      if (arch == host) {
        await _linuxNative(options: options, arch: arch);
      } else if (noDocker) {
        Log.info('Skipping Linux ${arch.name}: --no-docker was given and this '
            'host is ${host.name}.');
      } else {
        await DockerCrossBuilder.build(
          arch: arch,
          forwardFlags: rawFlags,
          image: image,
        );
      }
    }
  }

  static String? _valueOfFlag(Set<String> flags, String prefix) {
    for (final flag in flags) {
      if (flag.startsWith(prefix)) return flag.substring(prefix.length);
    }
    return null;
  }

  /// The original single-arch Linux build, running natively on this host.
  static Future<void> _linuxNative({
    required BuildOptions options,
    required LinuxArch arch,
  }) async {
    final rustRepos = _rustRepos(options);
    final cRepos = _cRepos(options);
    if (options.rust && rustRepos.isNotEmpty) {
      await RustBuilder.ensureToolchain();
      for (final repo in rustRepos) {
        await RustBuilder.buildForLinux(
          repo: repo,
          outputDir: options.linuxLibDir,
          release: !options.debug,
        );
      }
    }
    for (final repo in cRepos) {
      await CBuilder.buildForLinux(
        repo: repo,
        outputDir: options.linuxLibDir,
        release: !options.debug,
      );
    }
    await ProcessRunner.run('flutter', [
      'build',
      'linux',
      options.debug ? '--debug' : '--release',
    ]);

    final debArch = arch.debianArch;
    final buildMode = options.debug ? 'debug' : 'release';
    // Flutter writes the bundle under build/linux/<x64|arm64>/... depending
    // on the (container or host) architecture that ran the build.
    final bundleDirectory = Directory(
        'build/linux/${arch.flutterDir}/$buildMode/bundle'.normalizePath);
    if (!bundleDirectory.existsSync()) {
      throw CompilerError(
          'Expected bundle at ${bundleDirectory.path} but it does '
          'not exist; the flutter linux build may have failed.');
    }
    await FsUtils.zipDirectory(
        sourceDir: "${bundleDirectory.path}/".normalizePath,
        outputZip:
            "${options.releaseLocation}linux/${BuildConfig.appName}_$debArch.zip"
                .normalizePath);
    final deb = Directory(
        '${options.releaseLocation}linux/${BuildConfig.appName}_$debArch'
            .normalizePath);
    await _DebFileBuilder.createDebFile(
        displayName: "OnChain Wallet",
        version: "1.0.0",
        execName: BuildConfig.appName,
        packageName: BuildConfig.appName,
        applicationId: BuildConfig.packageName,
        outDir: deb,
        bundleDirectory: bundleDirectory,
        iconPath: BuildConfig.assetPath);
    Log.success('Linux ${arch.name} zip + deb written to '
            '${options.releaseLocation}linux/'
        .normalizePath);
  }

  static Future<void> ios({required BuildOptions options}) async {
    if (!Platform.isMacOS) {
      Log.info('iOS builds require macOS with Xcode; continuing anyway '
          '(this will likely fail on a non-macOS host).');
    }
    final rustRepos = _rustRepos(options);
    final cRepos = _cRepos(options);

    if (options.rust && rustRepos.isNotEmpty) {
      await RustBuilder.ensureToolchain();
      for (final repo in rustRepos) {
        await RustBuilder.buildForIos(
          repo,
          outputDir: options.iosLibDir,
          release: !options.debug,
        );
      }
    }
    for (final repo in cRepos) {
      await CBuilder.buildForIos(
        repo: repo,
        outputDir: options.iosLibDir,
        release: !options.debug,
      );
    }
    if (rustRepos.isNotEmpty || cRepos.isNotEmpty) {
      Log.info(
        'xcframeworks written to ${options.iosLibDir.path}/ios - add them to '
        'the Runner target in Xcode (General > Frameworks, Libraries, and '
        'Embedded Content) if they are not already linked.',
      );
    }

    await ProcessRunner.run('flutter', [
      'build',
      'ios',
      options.debug ? '--debug' : '--release',
      if (options.noCodesign) '--no-codesign',
    ]);
    final source = Directory('build/ios/iphoneos'.normalizePath);
    final destination =
        Directory('${options.releaseLocation}ios/'.normalizePath);
    if (source.existsSync()) {
      FsUtils.copyDirectory(source, destination, cleanDestination: true);
      Log.success('iOS build copied to ${destination.absolute.path}');
    } else {
      Log.info('build/ios/iphoneos not found (codesigning may have been '
          'skipped); the .app is under build/ios/.');
    }
  }
}

/// ---------------------------------------------------------------------------
/// Linux multi-arch support
/// ---------------------------------------------------------------------------

/// The two Linux desktop targets we always ship.
enum LinuxArch {
  x86_64('x86_64', 'amd64', 'x64', 'linux/amd64'),
  arm64('aarch64', 'arm64', 'arm64', 'linux/arm64');

  const LinuxArch(
      this.uname, this.debianArch, this.flutterDir, this.dockerPlatform);

  /// `uname -m` value for this arch.
  final String uname;

  /// Debian control-file architecture (amd64 / arm64).
  final String debianArch;

  /// Directory segment flutter uses: build/linux/<'flutterDir>/...
  final String flutterDir;

  /// Docker --platform value.
  final String dockerPlatform;

  static LinuxArch? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'x86_64':
      case 'amd64':
      case 'x64':
        return LinuxArch.x86_64;
      case 'aarch64':
      case 'arm64':
        return LinuxArch.arm64;
    }
    return null;
  }

  static Future<LinuxArch> host() async {
    final result = await Process.run('uname', ['-m']);
    final machine = (result.stdout as String).trim();
    final arch = fromString(machine);
    if (arch == null) {
      throw CompilerError(
          'Unsupported host architecture "$machine" for Linux builds.');
    }
    return arch;
  }
}

/// Builds the Flutter Linux app for a NON-native architecture by re-running
/// this very build tool inside a QEMU-emulated Docker container of the target
/// architecture. To Flutter, the container looks like a native arm64 (or
/// x86_64) host, so no cross-compilation hacks are needed - just patience,
/// since emulated builds are several times slower than native ones.
class DockerCrossBuilder {
  static const String defaultImage = 'ghcr.io/cirruslabs/flutter:stable';

  /// Flags that control multi-arch orchestration and must NOT be forwarded
  /// into the container (the inner invocation is single-arch by design).
  static const List<String> _orchestrationPrefixes = [
    '--linux-arch=',
    '--docker-image=',
    '--no-docker',
  ];

  static Future<void> ensureAvailable(LinuxArch arch) async {
    final docker = await Process.run('which', ['docker']);
    if (docker.exitCode != 0) {
      throw CompilerError(
          'Docker is required to build the ${arch.name} Linux target on this '
          'host but was not found on PATH. Install Docker, or pass '
          '--linux-arch=<native-arch> to build only the native target.');
    }
    // Probe whether the kernel can execute foreign-arch binaries (binfmt_misc
    // + QEMU). A tiny alpine container is enough to find out.
    final probe = await Process.run('docker', [
      'run',
      '--rm',
      '--platform',
      arch.dockerPlatform,
      'alpine',
      'uname',
      '-m'
    ]);
    if (probe.exitCode != 0 ||
        !(probe.stdout as String).trim().contains(arch.uname)) {
      throw CompilerError(
          'This host cannot run ${arch.dockerPlatform} containers. Enable '
          'QEMU emulation once with:\n'
          '  docker run --privileged --rm tonistiigi/binfmt --install all\n'
          'then re-run this build.\n(probe output: '
          '${(probe.stdout as String).trim()} ${(probe.stderr as String).trim()})');
    }
  }

  static String shellEscape(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  static Future<void> build({
    required LinuxArch arch,
    required Set<String> forwardFlags,
    required String image,
    // required bool rustEnabled,
  }) async {
    await ensureAvailable(arch);

    final containerName = 'onchain-builder-${arch.name}';

    final projectDir = Directory.current.absolute.path;

    final scriptPath = Platform.script.toFilePath();
    final relativeScript = scriptPath.startsWith(projectDir)
        ? scriptPath.substring(projectDir.length + 1)
        : 'tool/build.dart';
    forwardFlags = {
      ...forwardFlags,
      "--no-crypto-c",
      "--no-sqlite3",
      "--no-rust"
    };
    final innerFlags = forwardFlags
        .where((f) => !_orchestrationPrefixes.any((p) => f.startsWith(p)))
        .map(shellEscape)
        .join(' ');
    final setupScript = '''
set -e

apt-get update -qq

apt-get install -y -qq \
 clang \
 cmake \
 ninja-build \
 pkg-config \
 libgtk-3-dev \
 libsecret-1-dev \
 liblzma-dev \
 curl \
 git \
 unzip \
 zip \
 file \
 gcc \
 g++ \
 gcc-aarch64-linux-gnu \
 g++-aarch64-linux-gnu >/dev/null
}

git config --global --add safe.directory '*'
flutter config --enable-linux-desktop >/dev/null
''';
//     final setupScript = '''
// set -e

// apt-get update -qq
// apt-get install -y -qq \
//  clang cmake ninja-build pkg-config libgtk-3-dev \
//  liblzma-dev curl git unzip zip file gcc g++ \
//  gcc-aarch64-linux-gnu g++-aarch64-linux-gnu >/dev/null

// ${rustEnabled ? '''
// curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs \
//  | sh -s -- -y
// ''' : ''}

// git config --global --add safe.directory '*'
// flutter config --enable-linux-desktop >/dev/null
// ''';

    final script = '''
set -ex

echo "COMMAND:"
echo dart $relativeScript linux --linux-arch=${arch.name} --no-docker $innerFlags

cd /work
flutter pub get
flutter --version


dart $relativeScript linux --linux-arch=${arch.name} --no-docker $innerFlags
''';

    // Check if container exists
    final exists = await Process.run(
      'docker',
      [
        'inspect',
        containerName,
      ],
    );
    final uid = (await Process.run('id', ['-u'])).stdout.toString().trim();
    final gid = (await Process.run('id', ['-g'])).stdout.toString().trim();
    final dockerUser = Platform.isLinux ? '$uid:$gid' : 'root';
    if (exists.exitCode != 0) {
      Log.info('Creating docker builder $containerName');

      await ProcessRunner.run('docker', [
        'create',
        '--name',
        containerName,
        '--platform',
        arch.dockerPlatform,
        '-v',
        'onchain-pub-cache-${arch.name}:/home/.pub-cache',
        '-v',
        'onchain-cargo-cache-${arch.name}:/home/.cargo',
        '-v',
        '$projectDir:/work',
        '-w',
        '/work',
        image,
        'sleep',
        'infinity',
      ]);

      await ProcessRunner.run('docker', [
        'start',
        containerName,
      ]);

      // First-time setup
      await ProcessRunner.run('docker', [
        'exec',
        containerName,
        'bash',
        '-lc',
        setupScript,
      ]);
    }
    Log.info("run command $script");
    // Run build
    await ProcessRunner.run('docker', [
      'exec',
      '--user',
      dockerUser,
      containerName,
      'bash',
      '-lc',
      script,
    ]);
  }
//   static Future<void> build({
//     required LinuxArch arch,
//     required Set<String> forwardFlags,
//     required String image,
//     required bool rustEnabled,
//   }) async {
//     await ensureAvailable(arch);

//     // Re-invoke the same script that is currently running (works whether the
//     // file is named build.dart, build2.dart, ...).
//     final scriptPath = Platform.script.toFilePath();
//     final projectDir = Directory.current.absolute.path;
//     var relativeScript = scriptPath.startsWith(projectDir)
//         ? scriptPath.substring(projectDir.length + 1)
//         : 'tool/build.dart';

//     final innerFlags = forwardFlags
//         .where((f) => !_orchestrationPrefixes.any((p) => f.startsWith(p)))
//         .join(' ');

//     // Container setup: install the Linux desktop build dependencies (and rust
//     // when needed), then run the exact same tool for the single native arch.
//     final rustSetup = rustEnabled
//         ? 'if ! command -v cargo >/dev/null 2>&1; then '
//             'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; '
//             'fi; . "\$HOME/.cargo/env";'
//         : '';
//     final script = '''
// set -e
// export DEBIAN_FRONTEND=noninteractive
// apt-get update -qq
// apt-get install -y -qq clang cmake ninja-build pkg-config libgtk-3-dev gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
//   liblzma-dev curl git unzip zip file gcc g++ >/dev/null
// $rustSetup
// git config --global --add safe.directory '*'
// flutter config --enable-linux-desktop >/dev/null
// cd /work
// flutter pub get
// dart $relativeScript linux --linux-arch=${arch.name} --no-docker $innerFlags
// ''';

//     Log.info('Building Linux ${arch.name} inside a ${arch.dockerPlatform} '
//         'container (emulated - this is slow, grab a pizza)...');
//     await ProcessRunner.run('docker', [
//       'run',
//       '--rm',
//       '--platform',
//       arch.dockerPlatform,
//       // Persistent caches per arch so repeat builds are much faster.
//       '-v', 'onchain-pub-cache-${arch.name}:/root/.pub-cache',
//       '-v', 'onchain-cargo-cache-${arch.name}:/root/.cargo',
//       '-v', '$projectDir:/work',
//       '-w', '/work',
//       image,
//       'bash', '-lc', script,
//     ]);
//     Log.success('Linux ${arch.name} build finished (via Docker).');
//   }
}

/// ---------------------------------------------------------------------------
/// CLI
/// ---------------------------------------------------------------------------
class Cli {
  static const _helpFlags = {'-h', '--help'};

  static Future<void> run(List<String> args) async {
    if (args.isEmpty || _helpFlags.contains(args.first)) {
      _printHelp();
      return;
    }
    Log.info("Args $args");

    final command = args.first;
    final flags = args.skip(1).toSet();

    try {
      switch (command) {
        case 'clean':
          await ProcessRunner.flutterClean();
        case 'web':
          await WebAppBuilder.build(_parseOptions(flags));
        case 'extension':
          await _runExtension(flags);
        case 'apk':
          await NativeAppBuilder.apk(
            options: _parseOptions(flags),
            splitPerAbi: !flags.contains('--universal'),
          );
        case 'linux':
          await NativeAppBuilder.linux(
              options: _parseOptions(flags), rawFlags: flags);
        case 'macos':
          await NativeAppBuilder.macos(options: _parseOptions(flags));
        case 'windows':
          await NativeAppBuilder.windows(options: _parseOptions(flags));
        case 'ios':
          await NativeAppBuilder.ios(options: _parseOptions(flags));
        default:
          Log.error('Unknown command: $command\n');
          _printHelp();
          exitCode = 64; // EX_USAGE
      }
    } on BuildFailure catch (e) {
      Log.error(e.toString());
      exitCode = e.exitCode == 0 ? 1 : e.exitCode;
    }
  }

  static Future<void> _runExtension(Set<String> flags) async {
    final options = _parseOptions(flags);
    final target = _parseExtensionTarget(flags);
    final noScript = flags.contains('--no-script');
    final bool all = flags.contains('--all');

    // If none of the per-script flags are given, build all three scripts
    // (matches "full build" behaviour). Otherwise build only what's asked.
    final scriptFlagsGiven = flags.contains('--script-page') ||
        flags.contains('--script-content') ||
        flags.contains('--script-background');
    if (noScript && scriptFlagsGiven) {
      throw CompilerError("Bad build script argruments.");
    }

    await ExtensionBuilder.build(
      options,
      target: target,
      buildPageScript:
          !noScript && (!scriptFlagsGiven || flags.contains('--script-page')),
      buildContentScript: !noScript &&
          (!scriptFlagsGiven || flags.contains('--script-content')),
      buildBackgroundScript: !noScript &&
          (!scriptFlagsGiven || flags.contains('--script-background')),
    );
  }

  static ExtensionTarget _parseExtensionTarget(Set<String> flags) {
    if (flags.contains('--firefox')) return ExtensionTarget.firefox;
    if (flags.contains('--opera')) return ExtensionTarget.opera;
    if (flags.contains('--ie')) return ExtensionTarget.ie;
    return ExtensionTarget.chrome; // default
  }

  static BuildOptions _parseOptions(Set<String> flags) {
    final debug = flags.contains('--debug');
    final rustEnabled = !flags.contains('--no-rust');
    final cryptoCEnabled = !flags.contains('--no-crypto-c');
    final sqlite3Enabled = !flags.contains('--no-sqlite3');
    return BuildOptions(
      debug: debug,
      wasm: !flags.contains('--no-wasm'),
      crypto: !flags.contains('--no-crypto'),
      worker: !flags.contains('--no-worker'),
      webView: !flags.contains('--no-webview'),
      webViewWorker: !flags.contains('--no-webview-worker'),
      rust: rustEnabled,
      context: !flags.contains('--no-context'),
      production: flags.contains('--production'),
      noCodesign: !flags.contains('--codesign'),
      releaseLocation:
          _valueOf(flags, '--out=') ?? BuildConfig.defaultReleaseLocation,
      zkRepo: _rustRepo(
        flags: flags,
        enabled: rustEnabled,
        repository: RustRepository.zk,
        branch: _valueOf(flags, "--zk-branch="),
      ),
      netSdkRepo: _rustRepo(
        flags: flags,
        enabled: rustEnabled,
        repository: RustRepository.netSdk,
        branch: _valueOf(flags, "--net-sdk-branch="),
      ),
      cryptoC: _rustRepo(
        flags: flags,
        enabled: cryptoCEnabled,
        repository: RustRepository.cryptoC,
        branch: _valueOf(flags, "--crypto-c-branch="),
      ),
      sqlite3: _rustRepo(
          flags: flags,
          enabled: sqlite3Enabled,
          repository: RustRepository.sqllite,
          asset: NativeLiberaryAsset(
              fileName: "sqlite3mc-2.3.6-sqlite-3.53.3-amalgamation.zip",
              url:
                  "https://github.com/utelle/SQLite3MultipleCiphers/releases/download/v2.3.6/sqlite3mc-2.3.6-sqlite-3.53.3-amalgamation.zip",
              hash:
                  "bbd0434f9456d810cd1bb8d3767985f18f6b84648f1cd9cd1db6ccfb01819da2")),
      androidAbis: _valueOf(flags, '--android-abis=')
              ?.split(',')
              .map((s) => s.trim())
              .toList() ??
          const ['arm64-v8a', 'armeabi-v7a', 'x86_64'],
      androidApi: int.tryParse(_valueOf(flags, '--android-api=') ?? '') ??
          BuildConfig.defaultAndroidApi,
      jniLibsDir: _dirValueOf(flags, '--jni-libs-dir='),
      macosLibDir: _dirValueOf(flags, '--macos-lib-dir='),
      windowsLibDir: _dirValueOf(flags, '--windows-lib-dir='),
      iosLibDir: _dirValueOf(flags, '--ios-lib-dir='),
    );
  }

  /// Builds a [NativeLibraryConfig] from `--<x>-repo=`/`--<x>-branch=` flags,
  /// falling back to `<X>_REPO_URL`/`<X>_REPO_BRANCH` env vars. Returns null
  /// (rather than throwing) when the library is disabled entirely.
  static NativeLibraryConfig? _rustRepo({
    required Set<String> flags,
    required bool enabled,
    required RustRepository repository,
    String? branch,
    NativeLiberaryAsset? asset,
  }) {
    if (!enabled) return null;

    final url = repository.gitUrl;
    return NativeLibraryConfig(
        repository: repository,
        gitUrl: url,
        branch: branch ?? "main",
        asset: asset);
  }

  static String? _valueOf(Set<String> flags, String prefix) {
    for (final flag in flags) {
      if (flag.startsWith(prefix)) return flag.substring(prefix.length);
    }
    return null;
  }

  static Directory? _dirValueOf(Set<String> flags, String prefix) {
    final value = _valueOf(flags, prefix);
    return value == null ? null : Directory(value);
  }

  static void _printHelp() {
    print('''
Build tool for the on_chain_wallet Flutter app.

Usage: dart run tool/build.dart <command> [flags]

Commands:
  web         Build the plain Flutter web app.
  extension   Build a browser extension.
  apk         Build the Android APK.
  macos       Build the macOS app.
  windows     Build the Windows app.
  linux       Build the Linux app (zip + .deb).
  ios         Build the iOS app.
  clean       flutter clean && flutter pub get.

Common flags (all build commands):
  --debug              Debug build (default: release).
  --production         Use the production base href for web/extension.
  --out=<path>         Release output directory (default: ${BuildConfig.defaultReleaseLocation}).
  --no-wasm            Compile to JS instead of WASM.
  --no-crypto          Skip the crypto/stream_crypto script build.
  --no-worker          Skip the worker script build.
  --no-context         Skip the context script build.
  --no-rust            Skip fetching/building the rust crates (zk, net_sdk).
  --no-crypto-c        Skip building the crypto_c C library.
  --no-sqlite3         Skip building the sqlite3mc C library.

Native library sources:
  Rust crates (zk, net_sdk) are built with cargo. C libraries (crypto_c,
  sqlite3mc) are built with a C compiler resolved automatically per target,
  preferring gcc, then clang, then cc. Cross-compilers are used where needed
  (e.g. aarch64-linux-gnu-gcc, the Android NDK clang, or `xcrun clang` on
  Apple platforms).

  Sources are cloned into .rust_cache/<name> or .c_cache/<name> and kept in
  sync by commit sha: an unchanged remote HEAD is not re-downloaded.

  Target selection is automatic:
    web/extension -> wasm32-unknown-unknown via wasm-bindgen
    apk           -> one .so per Android ABI into jniLibs
    macos         -> universal (arm64 + x86_64) dylib via lipo
    windows       -> x64 .dll copied next to the exe
    linux         -> arm64 + x86_64 .so
    ios           -> device + simulator static libs bundled into an xcframework

Native output locations (override the defaults if your project differs):
  --android-abis=<a,b,c>       default: arm64-v8a,armeabi-v7a,x86_64
  --android-api=<n>            NDK min API for C libs (default: ${BuildConfig.defaultAndroidApi})
  --jni-libs-dir=<path>        default: android/app/src/main/jniLibs
  --macos-lib-dir=<path>       default: macos/Runner/NativeLibs
  --windows-lib-dir=<path>     default: windows/runner
  --ios-lib-dir=<path>         default: ios/Runner/NativeLibs

Rust Linux cross-linkers (optional):
  All currently configured environment variables start with CARGO_TARGET will be passed to the Rust compiler.

Extension-only flags:
  --chrome / --firefox / --opera / --ie   Target browser (default: chrome).
  --script-page / --script-content / --script-background
      Build only the given script(s) (default: build all three).

Android-only flags:
  --universal      Build one APK per ABI.

iOS-only flags:
  --codesign           Codesign the build (default: --no-codesign).

Examples:
  dart run tool/build.dart web --release --production
  dart run tool/build.dart extension --firefox --debug
  dart run tool/build.dart apk --release --universal
  dart run tool/build.dart macos --release
  dart run tool/build.dart windows --release --no-rust
  dart run tool/build.dart ios --release
''');
  }
}

Future<void> main(List<String> args) async {
  await Cli.run(args);
}

extension _PathNormalize on String {
  String get normalizePath => path.normalize(this);
}
