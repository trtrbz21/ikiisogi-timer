import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.displayUnit) private var unit: DisplayUnit = .minutes
    @AppStorage(SettingsKey.keepScreenOn) private var keepScreenOn = false
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system
    @AppStorage(SettingsKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingsKey.reminderMinutes) private var reminderMinutes = ReminderPlan.defaultMinutes
    @FocusState private var isEditingReminderMinutes: Bool
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
                    Toggle("残り時間を通知", isOn: reminderToggle)
                    if reminderEnabled {
                        LabeledContent("通知する残り時間") {
                            HStack(spacing: 4) {
                                TextField("60", value: $reminderMinutes, format: .number.grouping(.never))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .monospacedDigit()
                                    .frame(width: 64)
                                    .focused($isEditingReminderMinutes)
                                Text(DisplayUnit.minutes.shortLabel)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("締め時刻までの残り時間が、設定した分数になったときに通知します。")
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { isEditingReminderMinutes = false }
                }
            }
            // Keep the entered value within one day once editing ends.
            .onChange(of: isEditingReminderMinutes) { _, isEditing in
                if !isEditing {
                    reminderMinutes = min(max(reminderMinutes, ReminderPlan.allowedMinutes.lowerBound), ReminderPlan.allowedMinutes.upperBound)
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

    /// Turning the reminder on asks for notification permission first; if it is refused, the toggle stays off.
    private var reminderToggle: Binding<Bool> {
        Binding {
            reminderEnabled
        } set: { isOn in
            guard isOn else {
                reminderEnabled = false
                return
            }
            Task {
                if await ReminderScheduler.requestAuthorization() {
                    reminderEnabled = true
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
