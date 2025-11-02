class CardData {
  final SystemInfo system;
  final IssuePrimaryInfo issuePrimary;
  final AttributeInfo attribute;
  final LastTopupInfo? lastTopup;
  final Map<String, dynamic> unknown;
  final List<TransactionHistory> transactionHistory;
  final CommuterInfo? commuter;
  final List<GateInfo> gate;
  final List<SFGateInfo> sfGate;
  
  CardData({
    required this.system,
    required this.issuePrimary,
    required this.attribute,
    this.lastTopup,
    required this.unknown,
    required this.transactionHistory,
    this.commuter,
    required this.gate,
    required this.sfGate,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'system': system.toJson(),
      'issue_primary': issuePrimary.toJson(),
      'attribute': attribute.toJson(),
      'last_topup': lastTopup?.toJson(),
      'unknown': unknown,
      'transaction_history': transactionHistory.map((t) => t.toJson()).toList(),
      'commuter': commuter?.toJson(),
      'gate': gate.map((g) => g.toJson()).toList(),
      'sf_gate': sfGate.map((s) => s.toJson()).toList(),
    };
  }
}

class SystemInfo {
  final String idi;
  final String pmi;
  final String idm;
  final String pmm;
  
  SystemInfo({
    required this.idi,
    required this.pmi,
    required this.idm,
    required this.pmm,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'idi': idi,
      'pmi': pmi,
      'idm': idm,
      'pmm': pmm,
    };
  }
}

class IssuePrimaryInfo {
  final int issuerId;
  final String issuerName;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? issuedStation;
  
  IssuePrimaryInfo({
    required this.issuerId,
    required this.issuerName,
    this.issuedAt,
    this.expiresAt,
    this.issuedStation,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'issuer_id': issuerId,
      'issuer_name': issuerName,
      'issued_at': issuedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'issued_station': issuedStation,
    };
  }
}

class AttributeInfo {
  final String cardType;
  final int balance;
  final int transactionNumber;
  
  AttributeInfo({
    required this.cardType,
    required this.balance,
    required this.transactionNumber,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'card_type': cardType,
      'balance': balance,
      'transaction_number': transactionNumber,
    };
  }
}

class LastTopupInfo {
  final int amount;
  final DateTime date;
  
  LastTopupInfo({
    required this.amount,
    required this.date,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}

class TransactionHistory {
  final int index;
  final DateTime date;
  final String time;
  final String transactionType;
  final String payType;
  final int amount;
  final int balance;
  final String? entryStation;
  final String? exitStation;
  
  TransactionHistory({
    required this.index,
    required this.date,
    required this.time,
    required this.transactionType,
    required this.payType,
    required this.amount,
    required this.balance,
    this.entryStation,
    this.exitStation,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'date': date.toIso8601String(),
      'time': time,
      'transaction_type': transactionType,
      'pay_type': payType,
      'amount': amount,
      'balance': balance,
      'entry_station': entryStation,
      'exit_station': exitStation,
    };
  }
}

class CommuterInfo {
  final DateTime validFrom;
  final DateTime validTo;
  final String startStation;
  final String endStation;
  final String? via1;
  final String? via2;
  
  CommuterInfo({
    required this.validFrom,
    required this.validTo,
    required this.startStation,
    required this.endStation,
    this.via1,
    this.via2,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'valid_from': validFrom.toIso8601String(),
      'valid_to': validTo.toIso8601String(),
      'start_station': startStation,
      'end_station': endStation,
      'via1': via1,
      'via2': via2,
    };
  }
}

class GateInfo {
  final int index;
  final DateTime date;
  final String time;
  final String gateInOutType;
  final String station;
  
  GateInfo({
    required this.index,
    required this.date,
    required this.time,
    required this.gateInOutType,
    required this.station,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'date': date.toIso8601String(),
      'time': time,
      'gate_in_out_type': gateInOutType,
      'station': station,
    };
  }
}

class SFGateInfo {
  final int index;
  final DateTime date;
  final String time;
  final String station;
  
  SFGateInfo({
    required this.index,
    required this.date,
    required this.time,
    required this.station,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'date': date.toIso8601String(),
      'time': time,
      'station': station,
    };
  }
}
