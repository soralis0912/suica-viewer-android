import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class StationCodeLookup {
  Map<String, StationInfo> _stationMap = {};
  bool _isLoaded = false;
  
  bool get isLoaded => _isLoaded;
  
  Future<void> loadStationCodes() async {
    if (_isLoaded) return;
    
    try {
      final csvString = await rootBundle.loadString('assets/station_codes.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
      // Skip header row if it exists
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length >= 4) {
          final key = '${row[0]}_${row[1]}'; // company_code_line_code
          _stationMap[key] = StationInfo(
            companyCode: row[0].toString(),
            lineCode: row[1].toString(),
            stationCode: row[2].toString(),
            stationName: row[3].toString(),
            companyName: row.length > 4 ? row[4].toString() : '',
            lineName: row.length > 5 ? row[5].toString() : '',
          );
        }
      }
      
      _isLoaded = true;
    } catch (e) {
      throw Exception('Failed to load station codes: $e');
    }
  }
  
  StationInfo? lookupStation(int companyCode, int lineCode, int stationCode) {
    final key = '${companyCode}_$lineCode';
    return _stationMap[key];
  }
  
  String formatStation(int companyCode, int lineCode, int stationCode) {
    final station = lookupStation(companyCode, lineCode, stationCode);
    if (station != null) {
      return '${station.companyName} ${station.lineName} ${station.stationName}';
    }
    return 'Unknown Station ($companyCode-$lineCode-$stationCode)';
  }
}

class StationInfo {
  final String companyCode;
  final String lineCode;
  final String stationCode;
  final String stationName;
  final String companyName;
  final String lineName;
  
  StationInfo({
    required this.companyCode,
    required this.lineCode,
    required this.stationCode,
    required this.stationName,
    required this.companyName,
    required this.lineName,
  });
}
