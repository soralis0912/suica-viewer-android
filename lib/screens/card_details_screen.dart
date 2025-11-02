import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/card_data.dart';
import '../services/settings_service.dart';

class CardDetailsScreen extends StatefulWidget {
  final CardData cardData;
  
  const CardDetailsScreen({
    super.key,
    required this.cardData,
  });
  
  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FileService _fileService = FileService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _saveToFile() async {
    try {
      final file = await _fileService.saveCardDataAsJson(widget.cardData.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存しました: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _copyToClipboard() async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(widget.cardData.toJson());
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('クリップボードにコピーしました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('コピーに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カード詳細'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'クリップボードにコピー',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveToFile,
            tooltip: 'ファイルに保存',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: '概要'),
            Tab(icon: Icon(Icons.badge), text: '発行情報'),
            Tab(icon: Icon(Icons.history), text: '取引履歴'),
            Tab(icon: Icon(Icons.transit_enterexit), text: '改札履歴'),
            Tab(icon: Icon(Icons.data_object), text: 'JSON'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildIssueInfoTab(),
          _buildTransactionHistoryTab(),
          _buildGateHistoryTab(),
          _buildJsonTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard('システム情報', [
          _buildInfoRow('IDm', widget.cardData.system.idm),
          _buildInfoRow('PMm', widget.cardData.system.pmm),
          _buildInfoRow('IDi', widget.cardData.system.idi),
          _buildInfoRow('PMi', widget.cardData.system.pmi),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('カード情報', [
          _buildInfoRow('カード種別', widget.cardData.attribute.cardType),
          _buildInfoRow('残高', '¥${widget.cardData.attribute.balance}'),
          _buildInfoRow('取引通番', '${widget.cardData.attribute.transactionNumber}'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('発行情報', [
          _buildInfoRow('発行者', widget.cardData.issuePrimary.issuerName),
          _buildInfoRow('発行駅', widget.cardData.issuePrimary.issuedStation ?? '-'),
          _buildInfoRow('発行日', widget.cardData.issuePrimary.issuedAt?.toString().substring(0, 10) ?? '-'),
          _buildInfoRow('有効期限', widget.cardData.issuePrimary.expiresAt?.toString().substring(0, 10) ?? '-'),
        ]),
      ],
    );
  }
  
  Widget _buildIssueInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard('発行情報詳細', [
          _buildInfoRow('発行者ID', '${widget.cardData.issuePrimary.issuerId}'),
          _buildInfoRow('発行者名', widget.cardData.issuePrimary.issuerName),
          _buildInfoRow('発行駅', widget.cardData.issuePrimary.issuedStation ?? '-'),
          _buildInfoRow('発行日時', widget.cardData.issuePrimary.issuedAt?.toString() ?? '-'),
          _buildInfoRow('有効期限', widget.cardData.issuePrimary.expiresAt?.toString() ?? '-'),
        ]),
        const SizedBox(height: 16),
        if (widget.cardData.commuter != null)
          _buildInfoCard('定期券情報', [
            _buildInfoRow('有効期間開始', widget.cardData.commuter!.validFrom.toString().substring(0, 10)),
            _buildInfoRow('有効期間終了', widget.cardData.commuter!.validTo.toString().substring(0, 10)),
            _buildInfoRow('出発駅', widget.cardData.commuter!.startStation),
            _buildInfoRow('到着駅', widget.cardData.commuter!.endStation),
            if (widget.cardData.commuter!.via1 != null)
              _buildInfoRow('経由1', widget.cardData.commuter!.via1!),
            if (widget.cardData.commuter!.via2 != null)
              _buildInfoRow('経由2', widget.cardData.commuter!.via2!),
          ]),
      ],
    );
  }
  
  Widget _buildTransactionHistoryTab() {
    if (widget.cardData.transactionHistory.isEmpty) {
      return const Center(
        child: Text('取引履歴がありません'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: widget.cardData.transactionHistory.length,
      itemBuilder: (context, index) {
        final transaction = widget.cardData.transactionHistory[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            title: Text(transaction.transactionType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${transaction.date.toString().substring(0, 10)} ${transaction.time}'),
                if (transaction.entryStation != null || transaction.exitStation != null)
                  Text('${transaction.entryStation ?? '-'} → ${transaction.exitStation ?? '-'}'),
                Text('支払: ${transaction.payType}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${transaction.amount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.amount >= 0 ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  '残高: ¥${transaction.balance}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGateHistoryTab() {
    if (widget.cardData.gate.isEmpty) {
      return const Center(
        child: Text('改札履歴がありません'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: widget.cardData.gate.length,
      itemBuilder: (context, index) {
        final gate = widget.cardData.gate[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            title: Text(gate.gateInOutType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${gate.date.toString().substring(0, 10)} ${gate.time}'),
                Text(gate.station),
              ],
            ),
            leading: Icon(
              gate.gateInOutType.contains('入場') ? Icons.login : Icons.logout,
              color: gate.gateInOutType.contains('入場') ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildJsonTab() {
    final jsonString = const JsonEncoder.withIndent('  ').convert(widget.cardData.toJson());
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('クリップボードにコピー'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveToFile,
                  icon: const Icon(Icons.save),
                  label: const Text('ファイルに保存'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}
