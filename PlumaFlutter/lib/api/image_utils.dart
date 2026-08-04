import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static Future<String> compressToBase64(XFile file, {int maxDimension = 1000}) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Nieprawidlowy plik obrazu.');
    }
    return _toDataUrl(bytes, file.name);
  }

  static Future<String> convertVideoToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw const FormatException(
          'Plik wideo przekracza zalecany rozmiar (max ~2MB).');
    }
    return _toDataUrl(bytes, file.name);
  }

  static String _toDataUrl(List<int> bytes, String name) {
    final ext = _extensionOf(name);
    final mime = _mimeFor(ext);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'jpg';
    return name.substring(dot + 1).toLowerCase();
  }

  static String _mimeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'image/jpeg';
    }
  }

  static String formatJoinedDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'wrzesnia', 'pazdziernika', 'listopada', 'grudnia'
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} o $h:$m:$s';
  }
}
