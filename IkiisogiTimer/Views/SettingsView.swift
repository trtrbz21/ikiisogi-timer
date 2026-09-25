import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.displayUnit) private var unit: DisplayUnit = .minutes
    @AppStorage(SettingsKey.keepScreenOn) private var keepScreenOn = false
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("表示単位", selection: $unit) {
                        ForEach(DisplayUnit.allCases, id: \.self) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    Toggle("画面を常に点灯", isOn: $keepScreenOn)
                } header: {
                    Text("表示")
                } footer: {
                    Text("残り時間の数字をタップしても切り替えられます。分表示のときは、残り1分を切ると自動で秒表示になります。")
                }

                Section("外観") {
                    Picker("テーマ", selection: $appearance) {
                        ForEach(Appearance.allCases, id: \.self) { appearance in
                            Text(appearance.label).tag(appearance)
                        }
                    }
                }

                Section("このアプリについて") {
                    Link("サポート", destination: AppLinks.support)
                    Link("プライバシーポリシー", destination: AppLinks.privacyPolicy)
                    LabeledContent("バージョン", value: appVersion)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }
}

#Preview {
    SettingsView()
}
