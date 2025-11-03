import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_felica/nfc_manager_felica.dart';
import '../services/nfc_service.dart';
import '../services/auth_client.dart';
import '../services/station_lookup.dart';
import '../services/settings_service.dart';
import '../models/card_data.dart';
import '../controllers/card_parse_controller.dart';
import 'card_details_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SettingsService _settingsService = SettingsService();
  final StationCodeLookup _stationLookup = StationCodeLookup();
  final NFCService _nfcService = NFCService();
  
  String _status = 'NFC リーダーを初期化しています...';
  String? _error;
  String? _result;
  bool _isReading = false;
  double _progress = 0.0;
  CardData? _lastCardData;
  DateTime? _lastReadTime;
  late final CardParseController _cardParseController = CardParseController();
  void _onError(String message) {
    setState(() {
      _error = message;
      _status = 'エラーが発生しました';
      _isReading = false;
      _progress = 0.0;
    });
  }
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      await _settingsService.initialize();
      await _stationLookup.loadStationCodes();
      final nfcAvailable = await _nfcService.initialize();
      if (nfcAvailable) {
        setState(() {
          _status = 'カードをかざしてください。';
        });
      } else {
        setState(() {
          _status = 'NFC が利用できません。';
        });
      }
    } catch (e) {
      setState(() {
        _error = '初期化エラー: $e';
      });
    }
  }
  
  Future<void> _startNFCReading() async {
    if (_isReading || !_nfcService.isAvailable) return;
    setState(() {
      _isReading = true;
      _status = 'カードを読み取り中...';
      _error = null;
      _result = null;
      _progress = 0.0;
    });
    try {
      await _nfcService.startSession(
        onCardRead: _onCardRead,
        onError: _onError,
      );
    } catch (e) {
      _onError('NFC読み取りエラー: $e');
    }
  }
  
  Future<void> _stopNFCReading() async {
    if (!_isReading) return;
    try {
      await _nfcService.stopSession();
    } finally {
      setState(() {
        _isReading = false;
        _status = 'カードをかざしてください。';
        _progress = 0.0;
      });
    }
  }
  
  Future<void> _onCardRead(NfcTag tag) async {
    setState(() {
      _status = 'カード情報を取得しています...';
      _error = null;
      _result = null;
      _progress = 10.0;
    });

    final cardData = await _readCard(tag);

    try {
      setState(() {
        _status = '認証中...';
        _result = 'IDm: ${cardData.idmHex}\nPMm: ${cardData.pmmHex}';
        _progress = 30.0;
      });

      final authResult = await _mutualAuthenticate(cardData, tag);

      setState(() {
        _status = 'カードデータを解析中...';
        _progress = 80.0;
      });

      // Parse card data (simplified for demo)
      final parsedData = _cardParseController.parseCardData(cardData, authResult);

      setState(() {
        _status = '読み取り完了';
        _result = 'カードデータ取得成功';
        _progress = 100.0;
        _lastCardData = parsedData;
        _lastReadTime = DateTime.now();
      });

      // Auto-navigate to details screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CardDetailsScreen(cardData: parsedData),
          ),
        );
      }
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceFirst(RegExp(r'^Exception: '), '')
          : '$e';
      _onError('カード読み取りエラー: $message');
    } finally {
      await _stopNFCReading();
    }
  }

  Future<Map<String, dynamic>> _mutualAuthenticate(
    NFCCardData cardData,
    NfcTag tag,
  ) async {
    final authClient = FelicaRemoteClient(
      serverUrl: _settingsService.authServerUrl,
      bearerToken: _settingsService.authToken,
    );
    try {
      authClient.setCurrentTag(tag);
      final authResult = await authClient.mutualAuthentication(
        systemCode: NFCService.systemCode,
        areas: NFCService.areaNodeIds,
        services: NFCService.serviceNodeIds,
        idm: cardData.idmHex,
        pmm: cardData.pmmHex,
      );
      return authResult;
    } catch (e) {
      throw Exception('認証エラー: mutualAuthenticationで失敗: $e');
    } finally {
      authClient.dispose();
    }
  }

  Future<NFCCardData> _readCard(NfcTag tag) async {
    final felica = FeliCa.from(tag);
    if (felica == null) {
      throw Exception('This is not a FeliCa card');
    }
    final pmm = felica.pmm;
    final idm = felica.idm;
    final idmHex = idm.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    final pmmHex = pmm.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    return NFCCardData(
      idm: idmHex,
      pmm: pmmHex,
      systemCode: NFCService.systemCode,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suica Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.nfc,
                  size: 80,
                  color: _nfcService.isAvailable
                      ? (_isReading ? Colors.orange : Colors.green)
                      : Colors.grey,
                ),
                const SizedBox(height: 20),
                // ステータス表示
                SelectableText(
                  _status,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // エラー表示
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red[100],
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                // 結果表示
                if (_result != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.green[50],
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            _result!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                if (_isReading) ...[
                  LinearProgressIndicator(value: _progress / 100),
                  const SizedBox(height: 10),
                  Text('${_progress.toInt()}%'),
                ],
                const SizedBox(height: 40),
                if (!_isReading && _nfcService.isAvailable)
                  ElevatedButton.icon(
                    onPressed: _startNFCReading,
                    icon: const Icon(Icons.nfc),
                    label: const Text('カード読み取り開始'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                if (_isReading)
                  ElevatedButton.icon(
                    onPressed: _stopNFCReading,
                    icon: const Icon(Icons.stop),
                    label: const Text('読み取り停止'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_lastCardData != null && _lastReadTime != null) ...[
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    '最後の読み取り: ${_lastReadTime!.toString().substring(0, 19)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: Text('カード種別: ${_lastCardData!.attribute.cardType}'),
                      subtitle: Text('残高: ¥${_lastCardData!.attribute.balance}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CardDetailsScreen(
                              cardData: _lastCardData!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _stopNFCReading();
    super.dispose();
  }
}
