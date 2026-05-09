import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'error_utils.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  bool _isInitialized = false;
  String? _cachedDeviceId;
  String? _cachedDeviceName;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        _cachedDeviceId = androidInfo.id;
        _cachedDeviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        _cachedDeviceId = iosInfo.identifierForVendor;
        _cachedDeviceName = '${iosInfo.name} (${iosInfo.model})';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        _cachedDeviceId = windowsInfo.deviceId;
        _cachedDeviceName = '${windowsInfo.computerName} (Windows)';
} else if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        _cachedDeviceId = macInfo.systemGUID;
        _cachedDeviceName = '${macInfo.computerName} (macOS)';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        _cachedDeviceId = linuxInfo.machineId;
        _cachedDeviceName = '${linuxInfo.prettyName} (Linux)';
      } else {
        // Web or unknown platform
        _cachedDeviceId = Uuid().v4();
        _cachedDeviceName = 'Unknown Device';
      }
      
      _isInitialized = true;
    } catch (e) {
      ErrorUtils.logError('Failed to initialize device info service: $e');
      
      // Fallback to UUID
      _cachedDeviceId = Uuid().v4();
      _cachedDeviceName = 'Unknown Device';
      _isInitialized = true;
    }
  }
  
  Future<String?> getDeviceId() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedDeviceId;
  }
  
  Future<String?> getDeviceName() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedDeviceName;
  }
  
  Future<Map<String, dynamic>> getAllDeviceInfo() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final Map<String, dynamic> deviceInfo = {};
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceInfo['platform'] = 'Android';
        deviceInfo['version'] = androidInfo.version.release;
        deviceInfo['manufacturer'] = androidInfo.manufacturer;
        deviceInfo['model'] = androidInfo.model;
        deviceInfo['brand'] = androidInfo.brand;
        deviceInfo['device'] = androidInfo.device;
        deviceInfo['id'] = androidInfo.id;
        deviceInfo['isPhysicalDevice'] = androidInfo.isPhysicalDevice;
        deviceInfo['version_sdk'] = androidInfo.version.sdkInt;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceInfo['platform'] = 'iOS';
        deviceInfo['systemName'] = iosInfo.systemName;
        deviceInfo['systemVersion'] = iosInfo.systemVersion;
        deviceInfo['model'] = iosInfo.model;
        deviceInfo['name'] = iosInfo.name;
        deviceInfo['identifierForVendor'] = iosInfo.identifierForVendor;
        deviceInfo['isPhysicalDevice'] = iosInfo.isPhysicalDevice;
        deviceInfo['utsname.machine'] = iosInfo.utsname.machine;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        deviceInfo['platform'] = 'Windows';
        deviceInfo['computerName'] = windowsInfo.computerName;
        deviceInfo['deviceId'] = windowsInfo.deviceId;
        deviceInfo['productName'] = windowsInfo.productName;
        deviceInfo['displayVersion'] = windowsInfo.displayVersion;
        deviceInfo['buildNumber'] = windowsInfo.buildNumber;
} else if (Platform.isMacOS) {
      final macInfo = await _deviceInfoPlugin.macOsInfo;
      deviceInfo['platform'] = 'macOS';
      deviceInfo['computerName'] = macInfo.computerName;
      deviceInfo['hostName'] = macInfo.hostName;
      deviceInfo['arch'] = macInfo.arch;
      deviceInfo['model'] = macInfo.model;
      deviceInfo['kernelVersion'] = macInfo.kernelVersion;
      deviceInfo['osRelease'] = macInfo.osRelease;
      deviceInfo['activeCPUs'] = macInfo.activeCPUs;
      deviceInfo['memorySize'] = macInfo.memorySize;
      deviceInfo['cpuFrequency'] = macInfo.cpuFrequency;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        deviceInfo['platform'] = 'Linux';
        deviceInfo['name'] = linuxInfo.name;
        deviceInfo['version'] = linuxInfo.version;
        deviceInfo['id'] = linuxInfo.id;
        deviceInfo['idLike'] = linuxInfo.idLike;
        deviceInfo['versionCodename'] = linuxInfo.versionCodename;
        deviceInfo['versionId'] = linuxInfo.versionId;
        deviceInfo['prettyName'] = linuxInfo.prettyName;
        deviceInfo['buildId'] = linuxInfo.buildId;
        deviceInfo['variant'] = linuxInfo.variant;
        deviceInfo['variantId'] = linuxInfo.variantId;
        deviceInfo['machineId'] = linuxInfo.machineId;
      } else {
        deviceInfo['platform'] = kIsWeb ? 'Web' : 'Unknown';
        deviceInfo['id'] = _cachedDeviceId;
        deviceInfo['name'] = _cachedDeviceName;
      }
    } catch (e) {
      ErrorUtils.logError('Failed to get detailed device info: $e');
      deviceInfo['error'] = e.toString();
    }
    
    return deviceInfo;
  }
  
  bool isInitialized() {
    return _isInitialized;
  }
  
  Future<void> clearCache() async {
    _cachedDeviceId = null;
    _cachedDeviceName = null;
    _isInitialized = false;
  }
}
