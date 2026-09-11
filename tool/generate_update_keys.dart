import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final Ed25519 algorithm = Ed25519();
  final SimpleKeyPair keyPair = await algorithm.newKeyPair();

  final List<int> privateKeyBytes = await keyPair.extractPrivateKeyBytes();
  final SimplePublicKey publicKey = await keyPair.extractPublicKey();

  final String privateKeyBase64 = base64Encode(privateKeyBytes);
  final String publicKeyBase64 = base64Encode(publicKey.bytes);

  stdout.writeln('ED25519 key pair generated.');
  stdout.writeln('UPDATE_PUBLIC_KEY_BASE64=$publicKeyBase64');
  stdout.writeln('UPDATE_PRIVATE_KEY_BASE64=$privateKeyBase64');

  final File outFile = File('update_keys.local.json');
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, String>{
      'public_key_base64': publicKeyBase64,
      'private_key_base64': privateKeyBase64,
    }),
  );

  stdout.writeln('Saved local key file: ${outFile.path}');
}
