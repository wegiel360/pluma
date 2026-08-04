import 'dart:io' show Platform;
import 'api.dart';
import 'api_firedart.dart';
import 'api_flutterfire.dart';

/// Factory dla native (Android/Windows) — runtime check.
PlumaApi createApi() {
  if (Platform.isWindows) {
    return FiredartApi();
  }
  return FlutterFireApi();
}
