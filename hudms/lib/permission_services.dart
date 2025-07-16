import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions (storage, camera, location)
  static Future<void> requestAllPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.location,
      Permission.photos, // for iOS
    ].request();
  }

  /// Request individual permissions
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.status.isGranted;
  }

  /// Open App Settings
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}