import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showDeleteConfirm = false
    @State private var showPaywall = false

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRaw) ?? .system },
            set: { themeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // Pro
                    Section("Subscription") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Sprintly Pro — Active")
                                    .font(.subheadline.weight(.medium))
                            }
                            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                                Label("Manage Subscription", systemImage: "arrow.up.right.square")
                                    .foregroundStyle(Color.qmAccent)
                            }
                        } else {
                            Button {
                                Haptics.tap()
                                showPaywall = true
                            } label: {
                                Label("Upgrade to Pro — \(store.displayPrice)/mo", systemImage: "star.fill")
                                    .foregroundStyle(Color.qmAccent)
                            }
                            Button {
                                Haptics.tap()
                                Task { await store.restore() }
                            } label: {
                                Label("Restore Purchase", systemImage: "arrow.clockwise")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: theme) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Legal
                    Section("About") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/sprintly-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundStyle(.primary)
                        }
                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                            Label("Terms of Use", systemImage: "doc.text")
                                .foregroundStyle(.primary)
                        }
                    }

                    // Danger zone
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete all sprint data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) {
                    Haptics.warning()
                    appModel.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
        }
    }
}
