import SwiftUI

/// Light, dark, or whatever the phone is doing.
public enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Preferences that belong to the person, not to a franchise.
struct SettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            Form {
                Section {
                    Picker("Colour scheme", selection: $app.appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Both appearances are designed. System follows your phone.")
                }

                Section {
                    Toggle("Autosave", isOn: $app.autosaveEnabled)
                } header: {
                    Text("Franchise")
                } footer: {
                    Text("Your franchise is written after every move. Turning this off means "
                         + "only the saves you make yourself are kept.")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("League", value: "32 fictional teams")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
