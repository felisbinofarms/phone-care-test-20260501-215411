import SwiftUI

struct PrivacyView: View {
    @Environment(PermissionManager.self) private var permissionManager
    @State private var viewModel = PrivacyViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // Privacy score
                scoreSection

                // Summary stats
                summaryStats

                // Permission list
                permissionList
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.top, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.xl)
        }
        .background(Color.pcBackground)
        .accessibilityIdentifier("screen.privacy")
        .navigationTitle("Privacy")
        .refreshable {
            viewModel.load(permissionManager: permissionManager)
        }
        .onAppear {
            viewModel.load(permissionManager: permissionManager)
        }
        // Privacy share prompt removed — no user-initiated "cleanup win" moment here.
        // Privacy sharing is handled via CompletionCelebrationView in the Review Privacy guided flow.
    }

    // MARK: - Score

    private var scoreSection: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.md) {
                HealthScoreRingView(
                    score: viewModel.privacyScore,
                    lineWidth: 10,
                    size: 120
                )
                .accessibilityLabel("Privacy score: \(viewModel.privacyScore) out of 100")

                Text(viewModel.scoreSummary)
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.sm)
        }
        .accessibilityIdentifier("privacy.score")
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: PCTheme.Spacing.md) {
            statPill(count: viewModel.authorizedCount, label: "Allowed", color: .pcAccent)
            statPill(count: viewModel.deniedCount, label: "Denied", color: .pcTextSecondary)
            statPill(count: viewModel.notSetCount, label: "Not Set", color: .pcTextSecondary)
        }
    }

    private func statPill(count: Int, label: String, color: Color) -> some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.xs) {
                Text("\(count)")
                    .typography(.title3, color: color)

                Text(label)
                    .typography(.caption, color: .pcTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
        .accessibilityIdentifier("privacy.stat.\(label.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }

    // MARK: - Permission List

    private var permissionList: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            Text("Permissions")
                .typography(.headline)
                .voiceOverHeading()

            if viewModel.isLoading {
                CardView {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, PCTheme.Spacing.lg)
                        Spacer()
                    }
                }
            } else {
                ForEach(viewModel.permissions) { info in
                    NavigationLink {
                        PermissionDetailView(permissionType: info.type)
                    } label: {
                        permissionRow(info)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("privacy.permission.\(info.type.displayName.lowercased().replacingOccurrences(of: " ", with: "-"))")
                }
            }
        }
    }

    private func permissionRow(_ info: PrivacyPermissionInfo) -> some View {
        CardView {
            HStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: info.icon)
                    .font(.title3)
                    .foregroundStyle(info.statusColor)
                    .frame(width: 32, height: 32)
                    .voiceOverHidden()

                VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                    Text(info.type.displayName)
                        .typography(.subheadline)

                    Text(info.statusText)
                        .typography(.footnote, color: info.statusColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color.pcTextSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(info.type.displayName): \(info.statusText)")
        .accessibilityHint("Tap for details and suggestions")
    }
}
