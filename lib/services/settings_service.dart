import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SettingsService {
  static const String _authServerUrlKey = 'auth_server_url';
  static const String _defaultAuthServerUrl = 'https://felica-auth.nyaa.ws';
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }
  
  String get authServerUrl {
    _ensureInitialized();
    return _prefs.getString(_authServerUrlKey) ?? _defaultAuthServerUrl;
  }
  
  Future<void> setAuthServerUrl(String url) async {
    _ensureInitialized();
    await _prefs.setString(_authServerUrlKey, url);
  }
  
  Future<void> resetAuthServerUrl() async {
    _ensureInitialized();
    await _prefs.remove(_authServerUrlKey);
  }
  
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SettingsService not initialized. Call initialize() first.');
    }
  }
}

class FileService {
  Future<File> saveCardDataAsJson(Map<String, dynamic> cardData, {String? fileName}) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final finalFileName = fileName ?? 'suica_data_$timestamp.json';
    final file = File('${directory.path}/$finalFileName');
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(cardData);
    await file.writeAsString(jsonString);
    
    return file;
  }
  
  Future<Map<String, dynamic>?> loadCardDataFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load card data: $e');
    }
  }
  
  Future<List<File>> getSavedCardDataFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = await directory.list().where((entity) => 
      entity is File && entity.path.endsWith('.json') && 
      entity.path.contains('suica_data')
    ).cast<File>().toList();
    
    // Sort by modification date, newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }
  
  Future<void> deleteCardDataFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
