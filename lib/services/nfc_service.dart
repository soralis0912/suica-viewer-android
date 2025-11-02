import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_felica/nfc_manager_felica.dart';

class NFCService {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
  static const Duration sessionKeepAlive = Duration(seconds: 5); // セッション維持時間
  static const int systemCode = 0x0003;
  static const List<int> areaNodeIds = [0x0000, 0x0040, 0x0800, 0x0FC0, 0x1000];
  static const List<int> serviceNodeIds = [
    0x0048, 0x0088, 0x0810, 0x08C8, 0x090C,
    0x1008, 0x1048, 0x108C, 0x10C8
  ];
  
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  Future<bool> initialize() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (availability == NfcAvailability.enabled) {
        _isAvailable = true;
      } else {
        _isAvailable = false;
      }
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }
  
  Future<void> startSession({
    required Future<void> Function(NfcTag) onCardRead,
    required Function(String) onError,
  }) async {
    if (!_isAvailable) {
      onError('NFC is not available on this device');
      return;
    }
    
    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        int attempt = 0;
        while (attempt < maxRetries) {
          try {
            await onCardRead(tag);
            break;
          } catch (e) {
            // TagLostException のみリトライ
            if (e is Exception && e.toString().contains('TagLostException')) {
              attempt++;
              if (attempt >= maxRetries) {
                onError('TagLostException: カードが離れました。再度かざしてください。');
                break;
              }
              await Future.delayed(retryDelay);
            } else {
              onError('Failed to read card: $e');
              break;
            }
          }
        }
        // セッションを一定時間維持
        await Future.delayed(sessionKeepAlive);
      },
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092, // Required for FeliCa
      },
    );
  }
  
  Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }
  
  Future<Uint8List> exchangeWithCard(NfcTag tag, Uint8List command, {double? timeout}) async {
    try {
      // Try to get FeliCa from the tag
      final felica = FeliCa.from(tag);
      if (felica == null) {
        throw Exception('This is not a FeliCa card');
      }
      // Use the FeliCa sendFeliCaCommand method to exchange data
      final response = await felica.sendFeliCaCommand(commandPacket: command);
      return response;
    } catch (e) {
      throw Exception('Card exchange failed: $e');
    }
  }
  
  // Helper method to read specific services from FeliCa card
  Future<Map<int, Uint8List>> readFeliCaServices(NfcTag tag, List<int> serviceNodeIds) async {
    final results = <int, Uint8List>{};
    
    try {
      for (final serviceId in serviceNodeIds) {
        // Create read command for the specific service
        final felica = FeliCa.from(tag);
        if (felica != null) {
          // For demonstration - this would need proper FeliCa command construction
          final readCommand = _buildReadCommand(felica.idm, serviceId);
          final response = await exchangeWithCard(tag, readCommand);
          results[serviceId] = response;
        }
      }
    } catch (e) {
      throw Exception('Failed to read FeliCa services: $e');
    }
    
    return results;
  }
  
  // Build a FeliCa read command
  Uint8List _buildReadCommand(Uint8List idm, int serviceCode) {
    // FeliCa Read Without Encryption command (0x06)
    final commandBytes = <int>[];
    
    // Command code for Read Without Encryption
    commandBytes.add(0x06);
    
    // IDm (8 bytes)
    commandBytes.addAll(idm);
    
    // Service count (1 byte)
    commandBytes.add(0x01);
    
    // Service code (2 bytes, little endian)
    commandBytes.add(serviceCode & 0xFF);
    commandBytes.add((serviceCode >> 8) & 0xFF);
    
    // Block count (1 byte)
    commandBytes.add(0x01);
    
    // Block list (2 bytes for 1 block)
    commandBytes.add(0x80); // Block list element (access mode 0, service code order 0, block number 0)
    commandBytes.add(0x00);
    
    return Uint8List.fromList(commandBytes);
  }
}

class NFCCardData {
  final String idm;
  final String pmm;
  final int systemCode;
  
  NFCCardData({
    required this.idm,
    required this.pmm,
    required this.systemCode,
  });
  
  String get idmHex => idm;
  String get pmmHex => pmm;
}
