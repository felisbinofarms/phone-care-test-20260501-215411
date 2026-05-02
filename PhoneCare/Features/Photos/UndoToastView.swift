import SwiftUI

struct UndoToastView: View {
    let itemCount: Int
    /// Overrides the default title. Defaults to "N photos deleted" when nil.
    var title: String?
    /// Label for the action button. Defaults to "Undo".
    var buttonLabel: String
    let countdownDuration: TimeInterval
    var onAction: (() -> Void)?
    var onDismiss: (() -> Void)?

    @State private var remainingSeconds: Int
    @State private var timerTask: Task<Void, Never>?

    init(
        itemCount: Int,
        title: String? = nil,
        buttonLabel: String = "Undo",
        countdownDuration: TimeInterval = 30,
        onAction: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.itemCount = itemCount
        self.title = title
        self.buttonLabel = buttonLabel
        self.countdownDuration = countdownDuration
        self.onAction = onAction
        self.onDismiss = onDismiss
        _remainingSeconds = State(initialValue: Int(countdownDuration))
    }

    private var displayTitle: String {
        title ?? "\(itemCount) photos deleted"
    }

    var body: some View {
        HStack(spacing: PCTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                Text(displayTitle)
                    .typography(.subheadline)
                    .foregroundStyle(.white)

                Text("\(remainingSeconds)s")
                    .typography(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button {
                timerTask?.cancel()
                onAction?()
            } label: {
                Text(buttonLabel)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.pcAccent)
                    .padding(.horizontal, PCTheme.Spacing.md)
                    .padding(.vertical, PCTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
            }
            .accessibleTapTarget()
            .accessibilityHint(buttonLabel)
        }
        .padding(PCTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: PCTheme.Radius.md)
                .fill(Color.pcTextPrimary)
                .pcModalShadow()
        )
        .padding(.horizontal, PCTheme.Spacing.md)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear { startCountdown() }
        .onDisappear { timerTask?.cancel() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(displayTitle). \(remainingSeconds) seconds remaining.")
    }

    private func startCountdown() {
        timerTask?.cancel()
        remainingSeconds = Int(countdownDuration)
        timerTask = Task { @MainActor in
            while remainingSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remainingSeconds -= 1
            }
            if !Task.isCancelled {
                onDismiss?()
            }
        }
    }
}
