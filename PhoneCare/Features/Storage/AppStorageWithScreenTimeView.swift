import SwiftUI

struct AppStorageWithScreenTimeView: View {
    let category: StorageCategory
    @Environment(DataManager.self) private var dataManager

    @State private var details: [ScanDetail] = []
    @State private var screenTimeEnabled = false
    @State private var appUsageData: [String: Double] = [:]
    @State private var isLoadingScreenTime = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.lg) {
                // Header
                headerSection

                // Screen Time Status
                if !screenTimeEnabled {
                    screenTimeDisabledCard
                } else {
                    screenTimeInsightCard
                }

                // App Breakdown
                if !details.isEmpty {
                    appBreakdownSection
                } else {
                    emptyState
                }

                // Tips
                tipsSection
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.top, PCTheme.Spacing.md)
        }
        .background(Color.pcBackground)
        .navigationTitle(category.name)
        .onAppear {
            loadDetails()
            checkScreenTimeAvailability()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        CardView {
            HStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 44, height: 44)
                    .background(category.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: PCTheme.Radius.sm))
                    .voiceOverHidden()

                VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                    Text(category.name)
                        .typography(.headline)

                    Text(formatBytes(category.sizeInBytes))
                        .typography(.title3, color: .pcTextSecondary)

                    Text("\(String(format: "%.1f", category.percentage))% of total storage")
                        .typography(.footnote, color: .pcTextSecondary)
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Screen Time Card

    private var screenTimeDisabledCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                HStack(spacing: PCTheme.Spacing.sm) {
                    Image(systemName: "hourglass.bottomhalf.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)

                    Text("Screen Time Not Enabled")
                        .typography(.subheadline)

                    Spacer()

                    Image(systemName: "info.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                }

                Text("Enable Screen Time in Settings → Screen Time to see app usage alongside storage. This helps identify heavy users that take up space.")
                    .typography(.footnote, color: .pcTextSecondary)

                Button {
                    openScreenTimeSettings()
                } label: {
                    HStack {
                        Text("Open Settings")
                        Image(systemName: "arrow.up.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PCTheme.Spacing.sm)
                    .background(Color.pcAccent)
                    .foregroundStyle(.white)
                    .cornerRadius(PCTheme.Radius.md)
                    .typography(.footnote, weight: .semibold)
                }
                .accessibleTapTarget()
            }
        }
    }

    private var screenTimeInsightCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
                HStack {
                    HStack(spacing: PCTheme.Spacing.xs) {
                        Image(systemName: "hourglass.bottomhalf.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.pcAccent)

                        Text("Screen Time Active")
                            .typography(.subheadline)
                    }

                    Spacer()

                    Text("✓")
                        .foregroundStyle(Color.pcAccent)
                }

                Text("App usage is shown below. Apps you use frequently but don't open often might be cleanable.")
                    .typography(.footnote, color: .pcTextSecondary)
            }
        }
    }

    // MARK: - App Breakdown

    private var appBreakdownSection: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            Text(screenTimeEnabled ? "Apps by Space Used" : "Largest Apps")
                .typography(.headline)
                .voiceOverHeading()

            let sortedDetails = details.sorted { $0.sizeInBytes > $1.sizeInBytes }

            ForEach(sortedDetails.prefix(10), id: \.id) { detail in
                appRow(detail)
            }

            if details.count > 10 {
                NavigationLink {
                    VStack {
                        Text("All Apps")
                            .typography(.headline)
                            .padding()

                        ScrollView {
                            VStack(spacing: PCTheme.Spacing.sm) {
                                ForEach(sortedDetails, id: \.id) { detail in
                                    appRow(detail)
                                }
                            }
                            .padding(.horizontal, PCTheme.Spacing.md)
                        }
                    }
                    .background(Color.pcBackground)
                } label: {
                    HStack {
                        Text("Show all \(details.count) apps")
                            .typography(.footnote, color: .pcAccent)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(Color.pcAccent)
                    }
                    .padding(.top, PCTheme.Spacing.sm)
                }
            }
        }
    }

    private func appRow(_ detail: ScanDetail) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                HStack {
                    Text(detail.detailType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .typography(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    Text(formatBytes(detail.sizeInBytes))
                        .typography(.footnote, color: .pcAccent, weight: .semibold)
                }

                if let usageMinutes = appUsageData[detail.detailType], usageMinutes > 0 {
                    HStack(spacing: PCTheme.Spacing.xs) {
                        Image(systemName: "hourglass.circle")
                            .font(.caption2)
                            .foregroundStyle(Color.pcTextSecondary)

                        Text(formatUsageTime(usageMinutes))
                            .typography(.caption, color: .pcTextSecondary)

                        Spacer()

                        if usageMinutes > 60 {
                            Text("High usage")
                                .typography(.caption2)
                                .padding(.horizontal, PCTheme.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.pcAccent.opacity(0.2))
                                .foregroundStyle(Color.pcAccent)
                                .cornerRadius(4)
                        }
                    }
                }

                // Recommendation
                appRecommendation(for: detail)
            }
        }
    }

    private func appRecommendation(for detail: ScanDetail) -> some View {
        let usageMinutes = appUsageData[detail.detailType] ?? 0
        var recommendation = ""

        if usageMinutes == 0 {
            recommendation = "You haven't used this app recently. Safe to offload or delete."
        } else if usageMinutes < 5 {
            recommendation = "Minimal usage. Consider offloading if storage is tight."
        } else if detail.sizeInBytes > 500_000_000 {
            recommendation = "Large app. Check if you regularly use it; heavy data apps can be offloaded."
        } else {
            recommendation = "You use this regularly. Keep or offload with cache cleaned regularly."
        }

        return HStack(spacing: PCTheme.Spacing.xs) {
            Image(systemName: "lightbulb.fill")
                .font(.caption2)
                .foregroundStyle(Color.pcAccent)

            Text(recommendation)
                .typography(.caption2, color: .pcTextSecondary)
        }
        .padding(.top, PCTheme.Spacing.xs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(Color.pcTextSecondary)
                    .voiceOverHidden()

                Text("No app data yet")
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)

                Text("Run a scan from the home screen to get app storage information.")
                    .typography(.caption, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.lg)
        }
    }

    // MARK: - Tips

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            Text("Tips")
                .typography(.headline)
                .voiceOverHeading()

            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: PCTheme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.pcAccent)
                        .voiceOverHidden()

                    Text(tip)
                        .typography(.footnote, color: .pcTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, PCTheme.Spacing.lg)
    }

    private var tips: [String] {
        [
            "Offloading an app removes it but keeps your data. Reinstalling is quick.",
            "Apps cache data that can grow over time. Clear in Settings → General → Storage.",
            screenTimeEnabled ? "Apps you use frequently are generally worth keeping." : "Enable Screen Time to see which apps you actually use.",
            "Consider cloud storage (iCloud, Google Drive) for large media files."
        ]
    }

    // MARK: - Helpers

    private func loadDetails() {
        do {
            if let scan = try dataManager.latestScanResult() {
                details = (scan.details ?? []).filter { $0.category == "storage" && $0.detailType.contains("apps") }
            }
        } catch {
            details = []
        }
    }

    private func checkScreenTimeAvailability() {
        // Try to load Screen Time data if available
        // This is a simplified check; full implementation would use Family framework
        isLoadingScreenTime = true
        defer { isLoadingScreenTime = false }

        screenTimeEnabled = canAccessScreenTime()
        if screenTimeEnabled {
            loadScreenTimeData()
        }
    }

    private func canAccessScreenTime() -> Bool {
        // Check if Screen Time restriction is available
        // This requires FamilyControls entitlement and user permissions
        return false // Placeholder; would need entitlements
    }

    private func loadScreenTimeData() {
        // Placeholder implementation
        // In production, would query Family framework for app usage
        appUsageData = [:]
    }

    private func openScreenTimeSettings() {
        if let url = URL(string: "App-Prefs:root=SCREEN_TIME") {
            UIApplication.shared.open(url)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func formatUsageTime(_ minutes: Double) -> String {
        if minutes < 60 {
            return "\(Int(minutes))m"
        } else {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(mins)m"
        }
    }
}

// MARK: - Preview

#Preview {
    let category = StorageCategory(
        id: "apps",
        name: "Apps",
        icon: "square.grid.2x2.fill",
        color: .blue,
        sizeInBytes: 25_000_000_000,
        percentage: 20.8
    )

    AppStorageWithScreenTimeView(category: category)
}
