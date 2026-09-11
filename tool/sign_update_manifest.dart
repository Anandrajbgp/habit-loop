import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/sign_update_manifest.dart <manifest-file-path>');
    exitCode = 64;
    return;
  }

  final String privateKeyBase64 = Platform.environment['UPDATE_PRIVATE_KEY_BASE64'] ?? '';
  final String publicKeyBase64 = Platform.environment['UPDATE_PUBLIC_KEY_BASE64'] ?? '';
  if (privateKeyBase64.trim().isEmpty || publicKeyBase64.trim().isEmpty) {
    stderr.writeln('Missing UPDATE_PRIVATE_KEY_BASE64 or UPDATE_PUBLIC_KEY_BASE64 environment variable.');
    exitCode = 64;
    return;
  }

  final File manifestFile = File(args.first);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Manifest file not found: ${manifestFile.path}');
    exitCode = 66;
    return;
  }

  final dynamic raw = jsonDecode(await manifestFile.readAsString());
  if (raw is! Map<String, dynamic>) {
    stderr.writeln('Manifest must be a JSON object.');
    exitCode = 65;
    return;
  }

  final Map<String, dynamic> canonicalData = <String, dynamic>{
    'latest_version': (raw['latest_version'] ?? '').toString().trim(),
    'force_update': raw['force_update'] == true,
    'title': (raw['title'] ?? '').toString().trim(),
    'message': (raw['message'] ?? '').toString().trim(),
    'download_url': (raw['download_url'] ?? '').toString().trim(),
    'apk_sha256': (raw['apk_sha256'] ?? '').toString().trim().toLowerCase(),
  };

  final String canonicalPayload = jsonEncode(canonicalData);

  final Ed25519 algorithm = Ed25519();
  final List<int> privateKeyBytes = base64Decode(privateKeyBase64.trim());
  final List<int> publicKeyBytes = base64Decode(publicKeyBase64.trim());
  final SimpleKeyPair keyPair = SimpleKeyPairData(
    privateKeyBytes,
    type: KeyPairType.ed25519,
    publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
  );

  final Signature signature = await algorithm.sign(
    utf8.encode(canonicalPayload),
    keyPair: keyPair,
  );

  final String signatureBase64 = base64Encode(signature.bytes);

  final Map<String, dynamic> signedManifest = <String, dynamic>{
    ...canonicalData,
    'signature': signatureBase64,
  };

  await manifestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(signedManifest),
  );

  stdout.writeln('Manifest signed successfully: ${manifestFile.path}');
  stdout.writeln('SIGNATURE_BASE64=$signatureBase64');
}

