import SwiftUI
import UIKit

struct SharePromptView: View {
    let message: String
    let shareText: String
    var onDismiss: (() -> Void)?

    @State private var showShareSheet = false

    var body: some View {
        HStack(spacing: PCTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                Text(message)
                    .typography(.subheadline)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: PCTheme.Spacing.sm)

            Button {
                showShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.pcAccent)
                    .padding(.horizontal, PCTheme.Spacing.md)
                    .padding(.vertical, PCTheme.Spacing.sm)
                    .background(Capsule().fill(Color.white))
            }
            .accessibleTapTarget()
            .accessibilityHint("Opens the share sheet")

            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityLabel("Dismiss")
            .accessibilityHint("Dismiss the share prompt")
        }
        .padding(PCTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: PCTheme.Radius.md)
                .fill(Color.pcTextPrimary)
                .pcModalShadow()
        )
        .padding(.horizontal, PCTheme.Spacing.md)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [shareText])
                .presentationDetents([.medium])
        }
    }
}

// MARK: - UIActivityViewController Wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
