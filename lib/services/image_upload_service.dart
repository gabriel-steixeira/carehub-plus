/*
 * CareHub Plus — Services / Image Upload
 *
 * Serviço responsável por selecionar imagens do dispositivo e convertê-las
 * para base64, permitindo salvar diretamente no Firestore sem necessidade
 * de um serviço de storage externo.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Service for picking images and encoding them as base64 strings.
///
/// The images are compressed to 512×512 at 70% quality, keeping the base64
/// string around 30–60 KB — well within Firestore's 1 MB document limit.
class ImageUploadService {
  ImageUploadService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Opens the device gallery for the user to pick an image.
  ///
  /// Returns the selected [File] or `null` if cancelled.
  Future<File?> pickImageFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Opens the device camera for the user to take a photo.
  ///
  /// Returns the captured [File] or `null` if cancelled.
  Future<File?> pickImageFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Converts a [File] image to a base64-encoded string.
  ///
  /// Returns a data URI string (e.g. `data:image/jpeg;base64,...`) that can
  /// be stored directly in Firestore and decoded by the UI.
  Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    return 'data:image/jpeg;base64,$encoded';
  }
}
