import 'dart:typed_data';
import '../services/station_lookup.dart';
import '../constants/ic_card.dart';

class CardDataParser {
  final StationCodeLookup stationLookup;
  
  CardDataParser({required this.stationLookup});
  
  String equipmentTypeToString(int type) {
    return ICCard.equipmentTypes[type] ?? "不明な機器 (0x${type.toRadixString(16).padLeft(2, '0').toUpperCase()})";
  }
  
  String transactionTypeToString(int type) {
    return ICCard.transactionTypes[type] ?? "不明な取引 (0x${type.toRadixString(16).padLeft(2, '0').toUpperCase()})";
  }
  
  String payTypeToString(int type) {
    return ICCard.payTypes[type] ?? "不明な支払 (0x${type.toRadixString(16).padLeft(2, '0').toUpperCase()})";
  }
  
  String cardTypeToString(int type) {
    return ICCard.cardTypeLabels[type] ?? "不明なカード種別 (0x${type.toRadixString(16).padLeft(2, '0').toUpperCase()})";
  }
  
  String issuerIdToString(int id) {
    return ICCard.issuerIds[id] ?? "不明な発行者 ($id)";
  }
  
  DateTime formatDate(int dateValue) {
    // Convert from internal date format (days since 2000-01-01)
    final baseDate = DateTime(2000, 1, 1);
    return baseDate.add(Duration(days: dateValue));
  }
  
  String formatTime(Uint8List timeBytes) {
    if (timeBytes.length < 2) return "--:--";
    final timeHex = timeBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    if (timeHex.length >= 4) {
      return "${timeHex.substring(0, 2)}:${timeHex.substring(2, 4)}";
    }
    return "--:--";
  }
  
  String formatStation(int companyCode, int lineCode, int stationCode) {
    return stationLookup.formatStation(companyCode, lineCode, stationCode);
  }
  
  String idiToString(Uint8List idiBytes) {
    return idiBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }
  
  int bytesToInt(Uint8List bytes, {bool bigEndian = true}) {
    if (bytes.isEmpty) return 0;
    
    int result = 0;
    if (bigEndian) {
      for (int i = 0; i < bytes.length; i++) {
        result = (result << 8) + bytes[i];
      }
    } else {
      for (int i = bytes.length - 1; i >= 0; i--) {
        result = (result << 8) + bytes[i];
      }
    }
    return result;
  }
  
  Uint8List intToBytes(int value, int length, {bool bigEndian = true}) {
    final bytes = Uint8List(length);
    if (bigEndian) {
      for (int i = length - 1; i >= 0; i--) {
        bytes[i] = value & 0xFF;
        value >>= 8;
      }
    } else {
      for (int i = 0; i < length; i++) {
        bytes[i] = value & 0xFF;
        value >>= 8;
      }
    }
    return bytes;
  }
}
