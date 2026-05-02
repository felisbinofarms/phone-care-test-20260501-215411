import SwiftUI

struct DuplicateGroupView: View {
    let group: DuplicateGroup
    let groupIndex: Int
    let selectedIDs: Set<String>
    var onToggle: ((String) -> Void)?
    var onKeepBest: (() -> Void)?

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
                // Header
                HStack {
                    Text("Group \(groupIndex + 1)")
                        .typography(.headline)

                    Spacer()

                    Text("\(group.count) photos")
                        .typography(.footnote, color: .pcTextSecondary)
                }

                // Why were these grouped?
                HStack(spacing: PCTheme.Spacing.xs) {
                    Image(systemName: group.groupReason.iconName)
                        .font(.caption2)
                        .foregroundStyle(Color.pcTextSecondary)
                    Text(group.groupReason.displayText)
                        .typography(.caption, color: .pcTextSecondary)
                }

                // Grid
                PhotoGridView(
                    photoIDs: group.assetIdentifiers,
                    selectedIDs: selectedIDs,
                    onToggle: onToggle
                )

                // Keep Best button
                Divider()
                    .foregroundStyle(Color.pcBorder)

                HStack {
                    Button {
                        onKeepBest?()
                    } label: {
                        HStack(spacing: PCTheme.Spacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.footnote)
                            Text("Keep Best, Select Rest")
                        }
                    }
                    .textLinkStyle()
                    .accessibilityHint(group.keepReason)

                    Spacer()

                    if selectedIDs.contains(where: { group.assetIdentifiers.contains($0) }) {
                        let selectedInGroup = group.assetIdentifiers.filter { selectedIDs.contains($0) }.count
                        Text("\(selectedInGroup) selected")
                            .typography(.caption, color: .pcAccent)
                    }
                }

                // Why keep this one?
                Text(group.keepReason)
                    .typography(.caption, color: .pcTextSecondary)
                    .italic()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Duplicate group \(groupIndex + 1) with \(group.count) photos")
    }
}
