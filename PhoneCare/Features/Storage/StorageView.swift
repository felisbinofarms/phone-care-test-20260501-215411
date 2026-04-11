import SwiftUI

struct StorageView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var viewModel = StorageViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // Total / Used display
                storageOverview

                // Segmented bar chart
                if !viewModel.categories.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                            Text("Storage Breakdown")
                                .typography(.headline)
                                .voiceOverHeading()

                            StorageBarChart(
                                totalBytes: viewModel.totalStorage,
                                categories: viewModel.categories,
                                freeBytes: viewModel.freeStorage
                            )
                        }
                    }
                }

                // Category list with drill-down
                categoryList

                // Recommendations
                if !viewModel.recommendations.isEmpty {
                    recommendationsSection
                }
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.top, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.xl)
        }
        .background(Color.pcBackground)
        .navigationTitle("Storage")
        .refreshable {
            viewModel.load(dataManager: dataManager)
        }
        .onAppear {
            viewModel.load(dataManager: dataManager)
        }
    }

    // MARK: - Overview

    private var storageOverview: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                        Text("Used")
                            .typography(.footnote, color: .pcTextSecondary)
                        Text(viewModel.formatBytes(viewModel.usedStorage))
                            .typography(.title2)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: PCTheme.Spacing.xs) {
                        Text("Free")
                            .typography(.footnote, color: .pcTextSecondary)
                        Text(viewModel.formatBytes(viewModel.freeStorage))
                            .typography(.title2, color: .pcAccent)
                    }
                }

                // Simple progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pcBorder.opacity(0.3))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(usedColor)
                            .frame(width: geo.size.width * CGFloat(min(viewModel.usedPercentage, 100)) / 100)
                    }
                }
                .frame(height: 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Storage usage: \(Int(viewModel.usedPercentage)) percent used")

                Text("of \(viewModel.formatBytes(viewModel.totalStorage)) total")
                    .typography(.caption, color: .pcTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var usedColor: Color {
        // Use blue/green spectrum, never red for storage
        if viewModel.usedPercentage >= 90 {
            return .pcWarning
        } else if viewModel.usedPercentage >= 75 {
            return .blue
        } else {
            return .pcAccent
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            if !viewModel.categories.isEmpty {
                Text("Categories")
                    .typography(.headline)
                    .voiceOverHeading()

                ForEach(viewModel.categories) { category in
                    NavigationLink {
                        if category.id == "apps" {
                            AppStorageWithScreenTimeView(category: category)
                        } else {
                            CategoryDrillDownView(category: category)
                        }
                    } label: {
                        categoryRow(category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryRow(_ category: StorageCategory) -> some View {
        CardView {
            HStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(category.color)
                    .frame(width: 36, height: 36)
                    .background(category.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: PCTheme.Radius.sm))
                    .voiceOverHidden()

                VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                    Text(category.name)
                        .typography(.subheadline)

                    Text(viewModel.formatBytes(category.sizeInBytes))
                        .typography(.footnote, color: .pcTextSecondary)
                }

                Spacer()

                Text("\(String(format: "%.0f", category.percentage))%")
                    .typography(.footnote, color: .pcTextSecondary)

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color.pcTextSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Tap for details")
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            Text("Suggestions")
                .typography(.headline)
                .voiceOverHeading()

            ForEach(viewModel.recommendations) { rec in
                CardView {
                    HStack(spacing: PCTheme.Spacing.md) {
                        Image(systemName: rec.icon)
                            .font(.title3)
                            .foregroundStyle(Color.pcAccent)
                            .frame(width: 36, height: 36)
                            .voiceOverHidden()

                        VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                            Text(rec.title)
                                .typography(.subheadline)

                            Text(rec.description)
                                .typography(.footnote, color: .pcTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if rec.potentialSavings > 0 {
                                Text("Could save \(viewModel.formatBytes(rec.potentialSavings))")
                                    .typography(.footnote, color: .pcAccent)
                            }
                        }

                        Spacer()
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
