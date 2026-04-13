import SwiftUI

struct BatchDeleteSheet: View {
    let photoCount: Int
    let estimatedSize: Int64
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: PCTheme.Spacing.lg) {
            // Handle
            Capsule()
                .fill(Color.pcBorder)
                .frame(width: 36, height: 5)
                .padding(.top, PCTheme.Spacing.sm)
                .voiceOverHidden()

            // Icon
            Image(systemName: "trash")
                .font(.system(size: 40))
                .foregroundStyle(Color.pcTextSecondary)
                .padding(.top, PCTheme.Spacing.md)
                .voiceOverHidden()

            // Title
            Text("Delete \(photoCount) photos?")
                .typography(.title3)
                .multilineTextAlignment(.center)

            // Description
            Text("This will free up about \(formatBytes(estimatedSize)). iOS keeps deleted photos in Recently Deleted for 30 days, so you can recover them there if needed.")
                .typography(.subheadline, color: .pcTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PCTheme.Spacing.md)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Buttons
            VStack(spacing: PCTheme.Spacing.sm) {
                Button("Delete \(photoCount) Photos") {
                    onConfirm?()
                    dismiss()
                }
                .primaryCTAStyle()

                Button("Cancel") {
                    onCancel?()
                    dismiss()
                }
                .secondaryStyle()
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.lg)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
