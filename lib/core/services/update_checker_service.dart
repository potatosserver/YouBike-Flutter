import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:youbike/core/config/app_environment.dart';

class UpdateCheckResult {
  final bool isLatest;
  final String currentVersion;
  final String latestVersion;
  final String? releaseNotesUrl;
  final AppUpdateInfo? playUpdateInfo;
  final GithubReleaseInfo? githubRelease;
  final String? errorMessage;

  UpdateCheckResult({
    required this.isLatest,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotesUrl,
    this.playUpdateInfo,
    this.githubRelease,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
  bool get hasGooglePlayUpdate => playUpdateInfo != null;
  bool get hasGithubRelease => githubRelease != null;
}

class GithubReleaseInfo {
  final String tagName;
  final String htmlUrl;
  final String body;
  final List<dynamic> assets;

  GithubReleaseInfo({
    required this.tagName,
    required this.htmlUrl,
    required this.body,
    required this.assets,
  });

  factory GithubReleaseInfo.fromJson(Map<String, dynamic> json) {
    return GithubReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      assets: json['assets'] as List<dynamic>? ?? [],
    );
  }
}

class UpdateCheckerService {
  static const _githubLatestReleaseUrl =
      'https://api.github.com/repos/potatosserver/YouBike-Flutter/releases/latest';

  Future<UpdateCheckResult> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final channel = AppEnvironment.updateChannel.toLowerCase();

    try {
      if (channel == 'google_play') {
        final playUpdateInfo = await checkForGooglePlayUpdate();
        return UpdateCheckResult(
          isLatest: playUpdateInfo == null,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          playUpdateInfo: playUpdateInfo,
        );
      }

      if (channel == 'test') {
        return UpdateCheckResult(
          isLatest: true,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
        );
      }

      return await _checkGithubLatest(currentVersion);
    } catch (error) {
      return UpdateCheckResult(
        isLatest: true,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        errorMessage: error.toString(),
      );
    }
  }

  Future<AppUpdateInfo?> checkForGooglePlayUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        return updateInfo;
      }
      return null;
    } catch (error) {
      throw Exception('Google Play update check failed: $error');
    }
  }

  Future<void> startGooglePlayUpdate(AppUpdateInfo updateInfo) async {
    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      await InAppUpdate.performImmediateUpdate();
    }
  }

  Future<GithubReleaseInfo?> getLatestGithubRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_githubLatestReleaseUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      return GithubReleaseInfo.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getArchitecture() async {
    if (!Platform.isAndroid) {
      return null;
    }

    const availableApkAbis = {'arm64-v8a', 'armeabi-v7a', 'x86_64'};
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final supportedAbis = androidInfo.supportedAbis;

      for (final String abi in supportedAbis) {
        if (availableApkAbis.contains(abi)) {
          return abi;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> downloadGithubUpdate(
    GithubReleaseInfo release,
    String arch, {
    Function(double)? onProgress,
    Function(String)? onError,
    Function(String)? onStatus,
  }) async {
    try {
      final assets = release.assets;
      final apkName = 'app-$arch-release.apk';
      final apkAsset = assets.firstWhere(
        (asset) => asset['name'] == apkName,
        orElse: () => null,
      );

      if (apkAsset == null) {
        onError?.call('No compatible APK found for this device.');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/$apkName';
      final apkUrl = apkAsset['browser_download_url'] as String?;
      if (apkUrl == null) {
        onError?.call('Invalid download URL.');
        return null;
      }

      onStatus?.call('Downloading $apkName...');
      final dio = Dio();
      await dio.download(
        apkUrl,
        apkPath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            onProgress?.call(count / total);
          }
        },
      );

      onStatus?.call('Download complete.');
      return apkPath;
    } on DioException catch (e) {
      final message = e.message ?? 'Download failed.';
      onError?.call(message);
      return null;
    } catch (e) {
      onError?.call(e.toString());
      return null;
    }
  }

  Future<void> installFromPath(String apkPath) async {
    await OpenFilex.open(apkPath);
  }

  Future<UpdateCheckResult> _checkGithubLatest(String currentVersion) async {
    final latestRelease = await getLatestGithubRelease();
    if (latestRelease == null) {
      return UpdateCheckResult(
        isLatest: true,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
      );
    }

    final latestVersion = _normalizeVersion(latestRelease.tagName);
    final isLatest = !_isVersionNewer(currentVersion, latestVersion);

    return UpdateCheckResult(
      isLatest: isLatest,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseNotesUrl: latestRelease.htmlUrl,
      githubRelease: isLatest ? null : latestRelease,
    );
  }

  String _normalizeVersion(String rawVersion) {
    return rawVersion.trim().replaceFirst(RegExp(r'^[vV]+'), '');
  }

  bool _isVersionNewer(String current, String latest) {
    final currentSegments = _versionSegments(current);
    final latestSegments = _versionSegments(latest);
    for (var i = 0;
        i < currentSegments.length || i < latestSegments.length;
        i++) {
      final currentValue = i < currentSegments.length ? currentSegments[i] : 0;
      final latestValue = i < latestSegments.length ? latestSegments[i] : 0;
      if (latestValue > currentValue) return true;
      if (latestValue < currentValue) return false;
    }
    return false;
  }

  List<int> _versionSegments(String version) {
    return version
        .split(RegExp(r'[\.-]'))
        .map((segment) =>
            int.tryParse(segment.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}
