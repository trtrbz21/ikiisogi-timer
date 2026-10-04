import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.displayUnit) private var unit: DisplayUnit = .minutes
    @AppStorage(SettingsKey.keepScreenOn) private var keepScreenOn = false
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system
    @AppStorage(SettingsKey.reminders) private var remindersRaw = ""
    @State private var isShowingNotificationsOffAlert = false

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

                Section {
                    ForEach(ReminderPlan.options, id: \.self) { minutes in
                        Toggle("残り\(minutes)分", isOn: reminderBinding(for: minutes))
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("締め時刻までの残り時間が、選んだ長さになったときに通知します。")
                }

                Section("このアプリについて") {
                    Link("レビューを書く", destination: AppLinks.writeReview)
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
            .alert("通知が許可されていません", isPresented: $isShowingNotificationsOffAlert) {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("iPhoneの設定で、このアプリの通知を許可してください。")
            }
        }
    }

    /// Turning a reminder on asks for notification permission first; if it is refused, the toggle stays off.
    private func reminderBinding(for minutes: Int) -> Binding<Bool> {
        Binding {
            ReminderSelection.decode(remindersRaw).contains(minutes)
        } set: { isOn in
            var selection = ReminderSelection.decode(remindersRaw)
            guard isOn else {
                selection.remove(minutes)
                remindersRaw = ReminderSelection.encode(selection)
                return
            }
            Task {
                if await ReminderScheduler.requestAuthorization() {
                    // Re-read after the await in case another toggle changed meanwhile.
                    selection = ReminderSelection.decode(remindersRaw)
                    selection.insert(minutes)
                    remindersRaw = ReminderSelection.encode(selection)
                } else {
                    isShowingNotificationsOffAlert = true
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
