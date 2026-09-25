# 生き急ぎタイマー

1日の終わり（または設定した締め時刻）までの残り時間を「あと269分」「あと16,140秒」のように、分か秒のどちらか1つの単位だけで表示するiPhoneアプリです。

## 動作環境
- Xcode 27以降
- iOS 18以降（v1はiPhoneのみ）

## 構成
| パス | 内容 |
|---|---|
| `Shared/Countdown.swift` | 残り時間の計算（締め時刻、切り捨て、1分未満で秒表示に切り替え、進捗率） |
| `Shared/CountdownTimer.swift` | タイマーのデータ（毎日繰り返す／1回のみ） |
| `Shared/TimerStore.swift` | 端末内への保存（App GroupのUserDefaults。ウィジェットと共有） |
| `IkiisogiTimer/Views/` | ホーム・タイマー編集・設定の各画面 |
| `IkiisogiTimerWidget/` | ウィジェット |
| `IkiisogiTimerTests/` | 計算ロジックのユニットテスト |

## ビルドとテスト
Xcodeで `IkiisogiTimer.xcodeproj` を開き、実行（⌘R）またはテスト（⌘U）します。

コマンドラインで実行する場合：

```bash
xcodebuild test -project IkiisogiTimer.xcodeproj -scheme IkiisogiTimer -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

## ロードマップ
- [x] アプリアイコン（`swift Tools/generate-app-icon.swift` で再生成）
- [x] サポート・プライバシーポリシーのページ（`docs/`、GitHub Pages）
- [x] ウィジェット（ホーム画面 小・中、ロック画面 円形・長方形・1行、StandBy）
- [ ] ライブアクティビティ／Dynamic Island
- [ ] 通知・アラーム
- [ ] 複数タイマー
- [x] 多言語対応（英語）
- [ ] デザインテーマ
- [ ] iPad対応、iCloud同期
- [ ] 広告と広告削除の課金（またはPro版）
