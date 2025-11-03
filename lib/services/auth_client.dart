import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_felica/nfc_manager_felica.dart';

class FelicaRemoteClientError implements Exception {
  final String message;
  final int? code;
  
  FelicaRemoteClientError(this.message, [this.code]);
  
  @override
  String toString() => 'FelicaRemoteClientError: $message';
}

class CommandEnvelope {
  final Uint8List frame;
  final double? timeout;
  
  CommandEnvelope({required this.frame, this.timeout});
}

String? _normalizeBearerToken(String? token) {
  if (token == null) return null;
  final stripped = token.trim();
  return stripped.isEmpty ? null : stripped;
}

class FelicaRemoteClient {
  final String serverUrl;
  final http.Client _httpClient;
  String? sessionId;
  bool authenticated = false;
  final double httpTimeout;
  final double defaultExchangeTimeout;
  NfcTag? _currentTag;
  String? _bearerToken;
  
  FelicaRemoteClient({
    required this.serverUrl,
    this.httpTimeout = 10.0,
    this.defaultExchangeTimeout = 1.0,
    String? bearerToken,
  }) : _httpClient = http.Client(),
      _bearerToken = _normalizeBearerToken(bearerToken);
  
  void setCurrentTag(NfcTag tag) {
    _currentTag = tag;
  }
  
  void dispose() {
    _httpClient.close();
  }

  void setBearerToken(String? token) {
    _bearerToken = _normalizeBearerToken(token);
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_bearerToken != null) {
      headers['Authorization'] = 'Bearer $_bearerToken';
    }
    return headers;
  }
  
  Future<Map<String, dynamic>> mutualAuthentication({
    required int systemCode,
    required List<int> areas,
    required List<int> services,
    required String idm,
    required String pmm,
  }) async {
    try {
      final requestPayload = {
        'session_id': sessionId,
        'idm': idm,
        'pmm': pmm,
        'system_code': systemCode,
        'areas': areas,
        'services': services,
      };
      
      var response = await _post('/mutual-authentication', requestPayload);
      _updateSessionId(response);
      
      while (true) {
        final step = response['step'];
        if (step == 'auth1' || step == 'auth2') {
          final command = _extractCommand(response);
          final cardResponse = await _exchangeWithCard(command);
          response = await _post('/mutual-authentication', {
            'session_id': sessionId,
            'card_response': _bytesToHex(cardResponse),
          });
          _updateSessionId(response);
        } else if (step == 'complete') {
          authenticated = true;
          return response;
        } else {
          throw FelicaRemoteClientError('Unknown authentication step: $step');
        }
      }
    } catch (e) {
      throw FelicaRemoteClientError('mutualAuthentication failed: $e');
    }
  }
  
  Future<Uint8List> encryptionExchange({
    required int cmdCode,
    required Uint8List payload,
    double? timeout,
  }) async {
    try {
      if (!authenticated) {
        throw FelicaRemoteClientError(
          'mutual authentication must be completed first'
        );
      }
      
      final requestPayload = {
        'session_id': sessionId,
        'cmd_code': cmdCode,
        'payload': _bytesToHex(payload),
      };
      
      if (timeout != null) {
        requestPayload['timeout'] = timeout;
      }
      
      var response = await _post('/encryption-exchange', requestPayload);
      _updateSessionId(response);
      
      final command = _extractCommand(response);
      final cardResponse = await _exchangeWithCard(command);
      
      final finalResponse = await _post('/encryption-exchange', {
        'session_id': sessionId,
        'card_response': _bytesToHex(cardResponse),
      });
      _updateSessionId(finalResponse);
      
      final result = finalResponse['result'];
      if (result == null) {
        throw FelicaRemoteClientError('Missing result in encryption exchange response');
      }
      
      return _hexToBytes(result);
    } catch (e) {
      throw FelicaRemoteClientError('encryptionExchange failed: $e');
    }
  }
  
  CommandEnvelope _extractCommand(Map<String, dynamic> response) {
    try {
      final commandInfo = response['command'];
      final frameHex = commandInfo['frame'];
      final frame = _hexToBytes(frameHex);
      final timeoutValue = commandInfo['timeout'];
      final timeout = timeoutValue != null ? double.parse(timeoutValue.toString()) : null;
      
      return CommandEnvelope(frame: frame, timeout: timeout);
    } catch (e) {
      throw FelicaRemoteClientError('Invalid command data in response: $response');
    }
  }
  
  void _updateSessionId(Map<String, dynamic> response) {
    final newSessionId = response['session_id'];
    if (newSessionId != null) {
      sessionId = newSessionId;
    }
  }
  
  Future<Uint8List> _exchangeWithCard(CommandEnvelope command) async {
    if (_currentTag == null) {
      throw FelicaRemoteClientError('No NFC tag available for communication');
    }
    
    try {
      // Get FeliCa from the current tag
      final felica = FeliCa.from(_currentTag!);
      if (felica == null) {
        throw FelicaRemoteClientError('Current tag is not a FeliCa card');
      }
      // Exchange data with the card using the FeliCa sendFeliCaCommand method
    final response = await felica.sendFeliCaCommand(commandPacket: command.frame);
      return response;
    } catch (e) {
      throw FelicaRemoteClientError('Card exchange failed: $e');
    }
  }
  
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final url = Uri.parse('$serverUrl$path');
    
    try {
      final response = await _httpClient.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(payload),
      ).timeout(Duration(seconds: httpTimeout.toInt()));
      
      if (response.statusCode != 200) {
        final errorInfo = _extractErrorFromPayload(
          response.bodyBytes,
          'HTTP ${response.statusCode}',
        );
        final bodyText = response.body.trim();
        final message = _buildErrorMessage(errorInfo.message, bodyText);
        throw FelicaRemoteClientError(message, errorInfo.code);
      }
      
      return jsonDecode(response.body);
    } catch (e) {
      if (e is FelicaRemoteClientError) rethrow;
      throw FelicaRemoteClientError('Network error: $e');
    }
  }
  
  ({String message, int? code}) _extractErrorFromPayload(Uint8List data, String defaultReason) {
    try {
      final payload = jsonDecode(utf8.decode(data));
      final error = payload['error'] ?? {};
      final message = error['message'] ?? defaultReason;
      final code = error['code'];
      return (message: message, code: code);
    } catch (e) {
      return (message: defaultReason, code: null);
    }
  }

  String _buildErrorMessage(String baseMessage, String bodyText) {
    if (bodyText.isEmpty) {
      return baseMessage;
    }
    if (bodyText == baseMessage) {
      return baseMessage;
    }
    return '$baseMessage\n$bodyText';
  }
  
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
  
  Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw ArgumentError('Hex string must have even length');
    }
    
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}
