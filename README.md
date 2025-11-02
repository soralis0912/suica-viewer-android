# Suica Viewer (Flutter版)

Suica ViewerのFlutter移植版です。FeliCa ベースの交通系 IC カードから詳細な情報を取得し、表示・保存するためのAndroidアプリです。

## 機能

- **NFC読み取り**: Android端末のNFC機能を使用してFeliCaカードを読み取り
- **リモート認証**: 暗号領域の読み出しにリモート認証サーバーを利用
- **タブ表示**: 概要、発行情報、取引履歴、改札履歴、JSONの5つのタブで情報を整理表示
- **データ保存**: カード情報をJSONファイルとして保存
- **クリップボード**: カード情報をクリップボードにコピー
- **設定管理**: 認証サーバーURLの設定・管理
- **駅名解決**: station_codes.csvに基づく会社名・路線名・駅名の解決

## 必要環境

- Android 5.0 (API level 21) 以上
- NFC機能搭載端末
- インターネット接続（リモート認証サーバーとの通信のため）

## 技術スタック

- **Flutter 3.0+**: UIフレームワーク
- **Dart**: プログラミング言語
- **nfc_manager**: NFC通信プラグイン
- **http**: HTTP通信
- **shared_preferences**: 設定保存
- **csv**: CSVファイル解析

## プロジェクト構造

```
lib/
├── main.dart                    # アプリエントリーポイント
├── models/
│   └── card_data.dart          # カードデータモデル
├── services/
│   ├── auth_client.dart        # リモート認証クライアント
│   ├── nfc_service.dart        # NFC通信サービス
│   ├── station_lookup.dart     # 駅コードルックアップ
│   ├── card_parser.dart        # カードデータ解析
│   └── settings_service.dart   # 設定管理サービス
└── screens/
    ├── home_screen.dart        # ホーム画面
    ├── card_details_screen.dart # カード詳細画面
    └── settings_screen.dart    # 設定画面
```

## セットアップ

1. Flutter環境をセットアップ:
```bash
flutter doctor
```

2. 依存関係を取得:
```bash
flutter pub get
```

3. Android端末でアプリを実行:
```bash
flutter run
```

## 設定

### 認証サーバーURL
- デフォルト: `https://felica-auth.nyaa.ws`
- アプリの設定画面から変更可能
- 環境変数での設定（元のPython版の機能）は、Android版では設定画面からの管理に変更

### 注意事項
- 認証サーバーには個人情報やカード識別子などの機密データが送信される可能性があります
- 信頼できる環境でのみ接続してください

## 元プロジェクトとの違い

1. **GUI**: TkinterからFlutter Material Designに変更
2. **NFC**: nfcpyからnfc_managerプラグインに変更
3. **設定管理**: 環境変数からSharedPreferencesに変更
4. **ファイル保存**: デスクトップファイルシステムからAndroidドキュメントフォルダに変更

## ライセンス

MIT License

Copyright (c) 2025 soralis0912

## 注意

このアプリは実験的なものです。実際のFeliCaカードとの通信には、適切な権限と認証が必要です。カードの暗号化された領域へのアクセスは、正当な目的でのみ使用してください。
