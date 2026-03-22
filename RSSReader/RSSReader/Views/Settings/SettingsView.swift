import SwiftUI

struct SettingsView: View {
    @Environment(BackgroundRefreshManager.self) private var refreshManager

    var body: some View {
        @Bindable var manager = refreshManager

        Form {
            Section {
                Picker("Intervall", selection: $manager.refreshIntervalMinutes) {
                    Text("Manuell").tag(0)
                    Text("5 Minuten").tag(5)
                    Text("15 Minuten").tag(15)
                    Text("30 Minuten").tag(30)
                    Text("1 Stunde").tag(60)
                    Text("2 Stunden").tag(120)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            } header: {
                Text("Automatische Aktualisierung")
            } footer: {
                if manager.refreshIntervalMinutes > 0 {
                    Text("Feeds werden alle \(intervalDescription(manager.refreshIntervalMinutes)) automatisch aktualisiert.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Feeds werden nur manuell aktualisiert (⌘R).")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Benachrichtigungen") {
                Button("Berechtigung für Benachrichtigungen anfordern") {
                    NotificationService().requestPermission()
                }
                .buttonStyle(.link)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 220)
    }

    private func intervalDescription(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) Minuten"
        } else if minutes == 60 {
            return "eine Stunde"
        } else {
            return "\(minutes / 60) Stunden"
        }
    }
}
