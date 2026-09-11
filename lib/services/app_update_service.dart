import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  final String latestVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final String downloadUrl;
  final String apkSha256;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.downloadUrl,
    required this.apkSha256,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: (json['latest_version'] as String? ?? '').trim(),
      forceUpdate: json['force_update'] as bool? ?? false,
      title: (json['title'] as String? ?? 'Update available').trim(),
      message: (json['message'] as String? ?? 'A new update is available.').trim(),
      downloadUrl: (json['download_url'] as String? ?? '').trim(),
      apkSha256: (json['apk_sha256'] as String? ?? '').trim().toLowerCase(),
    );
  }
}

class AppUpdateService {
  // Replace this with your real hosted JSON URL.
  static const String _updateConfigUrl =
      'https://raw.githubusercontent.com/odlix/habitloop-updates/main/update.json';

  // Ed25519 public key in base64 (32 bytes). Replace with your production key.
  static const String _manifestPublicKeyBase64 =
      'KxRXxxJlpbxASRKlqy4GE82f+tsjoF8VrigaxY53cfs=';

  static Future<AppUpdateInfo?> checkForUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version.trim();

    final Uri uri = Uri.parse(_updateConfigUrl);
    if (uri.scheme.toLowerCase() != 'https') {
      return null;
    }

    final http.Response response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      return null;
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final bool verified = await _verifyManifestSignature(data);
    if (!verified) {
      return null;
    }

    final AppUpdateInfo info = AppUpdateInfo.fromJson(data);
    if (info.latestVersion.isEmpty ||
        info.downloadUrl.isEmpty ||
        info.apkSha256.length != 64) {
      return null;
    }

    final Uri downloadUri = Uri.parse(info.downloadUrl);
    if (downloadUri.scheme.toLowerCase() != 'https') {
      return null;
    }

    final bool hasUpdate = _isRemoteVersionNewer(currentVersion, info.latestVersion);
    return hasUpdate ? info : null;
  }

  static bool _isRemoteVersionNewer(String currentVersion, String remoteVersion) {
    final List<int> currentParts = _toVersionParts(currentVersion);
    final List<int> remoteParts = _toVersionParts(remoteVersion);
    final int maxLength = currentParts.length > remoteParts.length
        ? currentParts.length
        : remoteParts.length;

    for (int i = 0; i < maxLength; i++) {
      final int current = i < currentParts.length ? currentParts[i] : 0;
      final int remote = i < remoteParts.length ? remoteParts[i] : 0;

      if (remote > current) {
        return true;
      }
      if (remote < current) {
        return false;
      }
    }

    return false;
  }

  static Future<bool> _verifyManifestSignature(Map<String, dynamic> data) async {
    final String? signatureBase64 = data['signature'] as String?;
    if (signatureBase64 == null || signatureBase64.trim().isEmpty) {
      return false;
    }

    final String canonicalPayload = _canonicalizePayload(data);

    final List<int> publicKeyBytes = base64Decode(_manifestPublicKeyBase64);
    if (publicKeyBytes.length != 32) {
      return false;
    }

    final List<int> signatureBytes = base64Decode(signatureBase64.trim());
    if (signatureBytes.length != 64) {
      return false;
    }

    final Ed25519 algorithm = Ed25519();
    final SimplePublicKey publicKey =
        SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);

    return algorithm.verify(
      utf8.encode(canonicalPayload),
      signature: Signature(signatureBytes, publicKey: publicKey),
    );
  }

  static String _canonicalizePayload(Map<String, dynamic> data) {
    final Map<String, dynamic> canonical = <String, dynamic>{
      'latest_version': data['latest_version'] ?? '',
      'force_update': data['force_update'] ?? false,
      'title': data['title'] ?? '',
      'message': data['message'] ?? '',
      'download_url': data['download_url'] ?? '',
      'apk_sha256': data['apk_sha256'] ?? '',
    };

    return jsonEncode(canonical);
  }

  static List<int> _toVersionParts(String version) {
    final String sanitized = version.split('+').first.trim();
    final List<String> parts = sanitized.split('.');
    final List<int> result = <int>[];

    for (final String part in parts) {
      result.add(int.tryParse(part) ?? 0);
    }

    return result;
  }
}
