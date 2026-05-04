import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'error_utils.dart';

class NetworkInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize connectivity listener
      await _connectivity.checkConnectivity();
      _isInitialized = true;
    } catch (e) {
      ErrorUtils.logError('Failed to initialize network info service: $e');
      _isInitialized = true; // Still mark as initialized to allow fallback
    }
  }
  
  Future<String?> getIpAddress() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final wifiIP = await _networkInfo.getWifiIP();
        if (wifiIP != null && wifiIP.isNotEmpty && wifiIP != '0.0.0.0') {
          return wifiIP;
        }
        
        final cellularIP = await _networkInfo.getWifiIP(); // Note: getCellularIP may not be available
        if (cellularIP != null && cellularIP.isNotEmpty && cellularIP != '0.0.0.0') {
          return cellularIP;
        }
      }
      
      // Fallback for web or when above fails
      return await _getFallbackIpAddress();
    } catch (e) {
      ErrorUtils.logError('Failed to get IP address: $e');
      return await _getFallbackIpAddress();
    }
  }
  
  Future<String?> _getFallbackIpAddress() async {
    try {
      if (kIsWeb) {
        // Web platforms have limited IP access
        return null;
      }
      
      // Try to get IP from network interfaces
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
      
      return null;
    } catch (e) {
      ErrorUtils.logError('Failed to get fallback IP address: $e');
      return null;
    }
  }
  
  Future<ConnectivityResult> getConnectivityStatus() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      ErrorUtils.logError('Failed to get connectivity status: $e');
      return ConnectivityResult.none;
    }
  }
  
  Future<Map<String, dynamic>> getAllNetworkInfo() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final Map<String, dynamic> networkInfo = {};
    
    try {
      // Get IP addresses
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiIPv6 = await _networkInfo.getWifiIPv6();
      final wifiSubmask = await _networkInfo.getWifiSubmask();
      final wifiBroadcast = await _networkInfo.getWifiBroadcast();
      final wifiGateway = await _networkInfo.getWifiGatewayIP();
      
      networkInfo['wifi_ip'] = wifiIP;
      networkInfo['wifi_ipv6'] = wifiIPv6;
      networkInfo['wifi_submask'] = wifiSubmask;
      networkInfo['wifi_broadcast'] = wifiBroadcast;
      networkInfo['wifi_gateway'] = wifiGateway;
      
      // Get connectivity status
      final connectivity = await getConnectivityStatus();
      networkInfo['connectivity'] = connectivity.name;
      networkInfo['is_connected'] = connectivity != ConnectivityResult.none;
      
      // Get additional info based on platform
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final wifiName = await _networkInfo.getWifiName();
          final wifiBSSID = await _networkInfo.getWifiBSSID();
          
          networkInfo['wifi_name'] = wifiName?.replaceAll('"', '');
          networkInfo['wifi_bssid'] = wifiBSSID;
        } catch (e) {
          ErrorUtils.logInfo('Failed to get WiFi details: $e');
        }
      }
      
      // Get network interfaces
      try {
        final interfaces = await NetworkInterface.list();
        networkInfo['interfaces'] = interfaces.map((interface) {
          return {
            'name': interface.name,
            'addresses': interface.addresses.map((addr) => addr.address).toList(),
          };
        }).toList();
      } catch (e) {
        ErrorUtils.logInfo('Failed to get network interfaces: $e');
      }
      
    } catch (e) {
      ErrorUtils.logError('Failed to get network info: $e');
      networkInfo['error'] = e.toString();
    }
    
    return networkInfo;
  }
  
  Future<bool> hasInternetConnection() async {
    final connectivity = await getConnectivityStatus();
    
    if (connectivity == ConnectivityResult.none) {
      return false;
    }
    
    // For mobile/wifi, we assume there's internet
    // In a production app, you might want to actually test connectivity
    return true;
  }
  
  Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
  
  bool isInitialized() {
    return _isInitialized;
  }
  
  Future<void> clearCache() async {
    _isInitialized = false;
  }
}