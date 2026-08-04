import 'dart:convert';
import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:http/http.dart' as http;
import 'package:youbike/core/config/app_environment.dart';

class UpdateCheckResult {
  final bool isLatest;
  final String currentVersion;
  final String latestVersion;
  final String? releaseNotesUrl;
  final AppUpdateInfo? playUpdateInfo;
  final String? errorMessage;

  UpdateCheckResult({
    required this.isLatest,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotesUrl,
    this.playUpdateInfo,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
  bool get hasGooglePlayUpdate => playUpdateInfo != null;
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

  Future<UpdateCheckResult> checkForUpdate({required String currentVersion}) async {
    // 從 caller 注入 currentVersion，避免本檔再呼叫 PackageInfo.fromPlatform() —
    // 版號資訊統一由 AppConfigService.init 期間讀取並 cache。

    try {
      // Web build 不檢查更新：沒有原生的 in-app update 流程，
      // 也不應透過 GitHub API 提示使用者跳轉。
      if (AppEnvironment.isWeb) {
        return UpdateCheckResult(
          isLatest: true,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
        );
      }

      if (AppEnvironment.isGooglePlay) {
        final playUpdateInfo = await checkForGooglePlayUpdate();
        return UpdateCheckResult(
          isLatest: playUpdateInfo == null,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          playUpdateInfo: playUpdateInfo,
        );
      }

      if (AppEnvironment.isTest) {
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
    if (AppEnvironment.isWeb || !Platform.isAndroid) {
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
