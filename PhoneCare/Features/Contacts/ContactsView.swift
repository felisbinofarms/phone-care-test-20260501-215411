import SwiftUI

struct ContactsView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var viewModel = ContactsViewModel()
    @State private var selectedGroup: DuplicateContactGroup?
    @State private var showPaywall = false
    @State private var showSharePrompt = false
    @State private var sharePromptManager = SharePromptManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: PCTheme.Spacing.lg) {
                    // Summary header
                    summaryHeader

                    if viewModel.isScanning {
                        scanningState
                    } else if !viewModel.scanComplete {
                        scanPrompt
                    } else if viewModel.duplicateGroups.isEmpty {
                        emptyState
                    } else {
                        // Duplicate groups list
                        duplicateGroupsList
                    }
                }
                .padding(.horizontal, PCTheme.Spacing.md)
                .padding(.top, PCTheme.Spacing.md)
                .padding(.bottom, 100)
            }
            .background(Color.pcBackground)

            // Undo toast
            if viewModel.showUndoToast {
                UndoToastView(
                    itemCount: viewModel.lastMergedCount,
                    countdownDuration: 30,
                    onUndo: { viewModel.undoMerge(dataManager: dataManager) },
                    onDismiss: {
                        viewModel.showUndoToast = false
                        if sharePromptManager.shouldShowPrompt(dataManager: dataManager) {
                            withAnimation { showSharePrompt = true }
                            sharePromptManager.recordPromptShown(dataManager: dataManager)
                        }
                    }
                )
                .padding(.bottom, PCTheme.Spacing.xxl)
            }

            // Share prompt
            if showSharePrompt {
                SharePromptView(
                    message: SharePromptManager.promptMessage(for: .contactMerge(count: viewModel.lastMergedCount)),
                    shareText: SharePromptManager.shareMessage(for: .contactMerge(count: viewModel.lastMergedCount)),
                    onDismiss: { withAnimation { showSharePrompt = false } }
                )
                .padding(.bottom, PCTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Contacts")
        .onAppear { viewModel.load(dataManager: dataManager) }
        .sheet(item: $selectedGroup) { group in
            MergeComparisonView(
                group: group,
                onMerge: { viewModel.mergeGroup(group, dataManager: dataManager) },
                onCancel: { selectedGroup = nil }
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallBottomSheet()
        }
        .alert(item: $viewModel.alertInfo) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Summary

    private var summaryHeader: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundStyle(Color.pcAccent)
                        .voiceOverHidden()

                    VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                        Text("\(viewModel.totalContacts) contacts")
                            .typography(.headline)

                        if viewModel.duplicateCount > 0 {
                            Text("\(viewModel.duplicateCount) possible duplicates")
                                .typography(.subheadline, color: .pcTextSecondary)
                        } else {
                            Text("All contacts look good")
                                .typography(.subheadline, color: .pcTextSecondary)
                        }
                    }

                    Spacer()
                }

                if !viewModel.duplicateGroups.isEmpty {
                    Divider()
                        .foregroundStyle(Color.pcBorder)

                    Button("Merge All Duplicates") {
                        guard subscriptionManager.isPremium else {
                            showPaywall = true
                            return
                        }
                        viewModel.mergeAll(dataManager: dataManager)
                    }
                    .secondaryStyle()
                    .disabled(viewModel.isMerging)
                    .accessibilityHint("Automatically merge all duplicate contacts")
                }
            }
        }
    }

    // MARK: - Groups List

    private var duplicateGroupsList: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            Text("\(viewModel.duplicateGroups.count) groups")
                .typography(.headline)
                .voiceOverHeading()

            ForEach(viewModel.duplicateGroups) { group in
                Button {
                    if subscriptionManager.isPremium {
                        selectedGroup = group
                    } else {
                        showPaywall = true
                    }
                } label: {
                    groupRow(group)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func groupRow(_ group: DuplicateContactGroup) -> some View {
        CardView {
            HStack(spacing: PCTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.pcMintTint)
                        .frame(width: 44, height: 44)

                    Text(String(group.name.prefix(1)).uppercased())
                        .typography(.headline, color: .pcAccent)
                }
                .voiceOverHidden()

                VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                    Text(group.name)
                        .typography(.subheadline)

                    Text("\(group.contactIDs.count) entries")
                        .typography(.footnote, color: .pcTextSecondary)
                }

                Spacer()

                if subscriptionManager.isPremium {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                        .accessibilityLabel("Premium feature")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(subscriptionManager.isPremium ? "Tap to compare and merge" : "Premium feature")
    }

    // MARK: - States

    private var scanPrompt: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.lg) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.pcAccent)
                    .voiceOverHidden()

                Text("Find duplicate contacts")
                    .typography(.headline)
                    .multilineTextAlignment(.center)

                Text("We will look through your contacts for duplicates and help you merge them.")
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Scan Contacts") {
                    viewModel.startScan(dataManager: dataManager)
                }
                .primaryCTAStyle()
                .disabled(viewModel.isScanning || viewModel.isMerging)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.md)
        }
    }

    private var scanningState: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.lg) {
                ProgressView()
                    .controlSize(.large)

                Text("Scanning your contacts...")
                    .typography(.headline)

                Text("This should only take a moment.")
                    .typography(.subheadline, color: .pcTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.xl)
        }
    }

    private var emptyState: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.pcAccent)
                    .voiceOverHidden()

                Text("All clear!")
                    .typography(.headline)

                Text("No duplicate contacts found. Your address book is tidy.")
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.lg)
        }
    }
}
