import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits = [
        ("clock.arrow.circlepath", "Archive of every past sprint with win-rate and momentum trends"),
        ("flag.2.crossed", "Multiple concurrent weekly goals and custom sprint lengths"),
        ("bell.badge", "Mid-sprint check-in reminders and a weekly kickoff prompt")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        // Icon + title
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.qmCard)
                                    .frame(width: 88, height: 88)
                                Image(systemName: "flag.checkered.2.crossed")
                                    .font(.system(size: 42, weight: .light))
                                    .foregroundStyle(Color.qmAccent)
                            }
                            Text("Sprintly Pro")
                                .font(.title.weight(.bold))
                            Text("$0.99 / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)

                        // Benefits
                        VStack(spacing: 0) {
                            ForEach(Array(benefits.enumerated()), id: \.offset) { _, benefit in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: benefit.0)
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.qmAccent)
                                        .frame(width: 28)
                                    Text(benefit.1)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                if benefit.0 != benefits.last?.0 {
                                    Divider()
                                }
                            }
                        }
                        .qmCard()
                        .padding(.horizontal)

                        // Unlock button
                        VStack(spacing: 12) {
                            Button {
                                Haptics.tap()
                                Task { await store.purchase() }
                            } label: {
                                if store.purchaseInFlight {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Unlock for \(store.displayPrice)/mo")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .prominentButton()
                            .disabled(store.purchaseInFlight)
                            .padding(.horizontal)

                            Button("Restore Purchase") {
                                Haptics.tap()
                                Task { await store.restore() }
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.qmAccent)
                        }

                        // Legal
                        VStack(spacing: 8) {
                            Text("Subscription automatically renews at \(store.displayPrice)/month unless cancelled at least 24 hours before the end of the current period. Manage your subscription in App Store settings.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/sprintly-site/privacy.html")!)
                            }
                            .font(.caption)
                            .foregroundStyle(Color.qmAccent)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, newVal in
                if newVal { dismiss() }
            }
        }
    }
}
