import SwiftUI
import UIKit

struct PhotosView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var viewModel = PhotosViewModel()
    @State private var showPaywall = false
    @State private var showSharePrompt = false
    @State private var sharePromptManager = SharePromptManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: PCTheme.Spacing.lg) {
                    // Segment picker
                    categoryPicker

                    // Results count header
                    resultsHeader

                    // Content
                    if viewModel.isScanning {
                        scanningState
                    } else if viewModel.permissionDenied {
                        permissionNeededState
                    } else if !viewModel.scanComplete {
                        scanPrompt
                    } else if viewModel.hasResults {
                        categoryContent
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, PCTheme.Spacing.md)
                .padding(.top, PCTheme.Spacing.md)
                .padding(.bottom, 100)
            }
            .background(Color.pcBackground)

            // Bottom toolbar when items selected
            if viewModel.selectedCount > 0 {
                selectionToolbar
            }

            // Undo toast
            if viewModel.showUndoToast {
                UndoToastView(
                    itemCount: viewModel.lastDeletedCount,
                    onUndo: { viewModel.undoDelete() },
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
                    message: SharePromptManager.promptMessage(for: .photoDelete(bytesFreed: viewModel.lastDeletedSize)),
                    shareText: SharePromptManager.shareMessage(for: .photoDelete(bytesFreed: viewModel.lastDeletedSize)),
                    onDismiss: { withAnimation { showSharePrompt = false } }
                )
                .padding(.bottom, PCTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Photos")
        .onAppear { viewModel.load(dataManager: dataManager) }
        .sheet(isPresented: $viewModel.showBatchDeleteSheet) {
            BatchDeleteSheet(
                photoCount: viewModel.selectedCount,
                estimatedSize: Int64(viewModel.selectedCount) * 3_500_000,
                onConfirm: { viewModel.confirmBatchDelete() },
                onCancel: { viewModel.showBatchDeleteSheet = false }
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallBottomSheet()
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PCTheme.Spacing.sm) {
                ForEach(PhotoCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: PCTheme.Spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.footnote)
                            Text(category.rawValue)
                                .typography(.footnote)
                        }
                        .padding(.horizontal, PCTheme.Spacing.md)
                        .padding(.vertical, PCTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedCategory == category ? Color.pcAccent : Color.pcMintTint)
                        )
                        .foregroundStyle(viewModel.selectedCategory == category ? .white : Color.pcAccent)
                    }
                    .accessibleTapTarget()
                    .accessibilityAddTraits(viewModel.selectedCategory == category ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, PCTheme.Spacing.xs)
        }
    }

    // MARK: - Results Header

    private var resultsHeader: some View {
        HStack {
            Text(viewModel.currentCategoryDescription)
                .typography(.subheadline, color: .pcTextSecondary)

            Spacer()

            if viewModel.hasResults && viewModel.selectedCategory != .screenshots && viewModel.selectedCategory != .blurry && viewModel.selectedCategory != .largeVideos {
                // No select-all for groups; handled within groups
            } else if viewModel.hasResults {
                Button("Select All") {
                    let ids: [String]
                    switch viewModel.selectedCategory {
                    case .screenshots: ids = viewModel.screenshotIDs
                    case .blurry: ids = viewModel.blurryIDs
                    case .largeVideos: ids = viewModel.largeVideoIDs
                    default: ids = []
                    }
                    viewModel.selectAll(in: ids)
                }
                .textLinkStyle()
                .accessibleTapTarget()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var categoryContent: some View {
        switch viewModel.selectedCategory {
        case .duplicates:
            duplicatesContent
        case .screenshots:
            screenshotsByAgeContent
        case .blurry:
            PhotoGridView(
                photoIDs: viewModel.blurryIDs,
                selectedIDs: viewModel.selectedPhotoIDs,
                onToggle: { viewModel.toggleSelection($0) }
            )
        case .largeVideos:
            PhotoGridView(
                photoIDs: viewModel.largeVideoIDs,
                selectedIDs: viewModel.selectedPhotoIDs,
                onToggle: { viewModel.toggleSelection($0) }
            )
        }
    }

    private var screenshotsByAgeContent: some View {
        let ageGroups = viewModel.screenshotsByAge()
        return VStack(spacing: PCTheme.Spacing.md) {
            if ageGroups.isEmpty {
                PhotoGridView(
                    photoIDs: viewModel.screenshotIDs,
                    selectedIDs: viewModel.selectedPhotoIDs,
                    onToggle: { viewModel.toggleSelection($0) }
                )
            } else {
                ForEach(ageGroups) { group in
                    VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
                        HStack {
                            Text("\(group.title) (\(group.ids.count))")
                                .typography(.headline)

                            Spacer()

                            Button("Select All") {
                                viewModel.selectAllInAgeGroup(group)
                            }
                            .font(.footnote)
                            .foregroundStyle(Color.pcAccent)
                        }

                        PhotoGridView(
                            photoIDs: group.ids,
                            selectedIDs: viewModel.selectedPhotoIDs,
                            onToggle: { viewModel.toggleSelection($0) }
                        )
                    }
                }
            }
        }
    }

    private var duplicatesContent: some View {
        let groups = viewModel.visibleDuplicateGroups(isPremium: subscriptionManager.isPremium)
        return VStack(spacing: PCTheme.Spacing.md) {
            ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                DuplicateGroupView(
                    group: group,
                    groupIndex: index,
                    selectedIDs: viewModel.selectedPhotoIDs,
                    onToggle: { viewModel.toggleSelection($0) },
                    onKeepBest: {
                        // Select all except first (best)
                        let rest = Array(group.dropFirst())
                        viewModel.selectAll(in: rest)
                    }
                )
            }

            premiumGateMessage(
                totalCount: viewModel.duplicateGroups.count,
                shownCount: groups.count
            )
        }
    }

    @ViewBuilder
    private func premiumGateMessage(totalCount: Int, shownCount: Int) -> some View {
        if !subscriptionManager.isPremium && totalCount > shownCount {
            CardView {
                VStack(spacing: PCTheme.Spacing.md) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(Color.pcTextSecondary)
                        .voiceOverHidden()

                    Text("\(totalCount - shownCount) more groups available with Premium")
                        .typography(.subheadline, color: .pcTextSecondary)
                        .multilineTextAlignment(.center)

                    Button("Unlock All") {
                        showPaywall = true
                    }
                    .primaryCTAStyle()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PCTheme.Spacing.sm)
            }
        }
    }

    // MARK: - States

    private var scanPrompt: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.lg) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.pcAccent)
                    .voiceOverHidden()

                Text("Ready to find photos to clean up")
                    .typography(.headline)
                    .multilineTextAlignment(.center)

                Text("We will look for duplicates, screenshots, blurry photos, and large videos.")
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Scan Photos") {
                    viewModel.startScan(dataManager: dataManager)
                }
                .primaryCTAStyle()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.md)
        }
    }

    private var scanningState: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.lg) {
                ProgressView(value: viewModel.scanProgress)
                    .progressViewStyle(.linear)
                    .tint(Color.pcAccent)

                Text(viewModel.scanStatusMessage.isEmpty
                     ? "Scanning your photos..."
                     : viewModel.scanStatusMessage)
                    .typography(.headline)

                Text("This may take a moment depending on your library size.")
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

                Text("Looking good!")
                    .typography(.headline)

                Text("No \(viewModel.selectedCategory.rawValue.lowercased()) found. Your photo library is tidy.")
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.lg)
        }
    }

    private var permissionNeededState: some View {
        CardView {
            VStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.pcTextSecondary)
                    .voiceOverHidden()

                Text("Photos access needed")
                    .typography(.headline)

                Text("To find duplicates and free up space, PhoneCare needs access to your photo library. You can grant access in Settings.")
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .primaryCTAStyle()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.lg)
        }
    }

    // MARK: - Selection Toolbar

    private var selectionToolbar: some View {
        HStack {
            Button("Clear") {
                viewModel.deselectAll()
            }
            .textLinkStyle()
            .accessibleTapTarget()

            Spacer()

            Text("\(viewModel.selectedCount) selected")
                .typography(.headline)

            Spacer()

            Button("Delete") {
                viewModel.prepareBatchDelete()
            }
            .primaryCTAStyle()
            .frame(width: 120)
        }
        .padding(PCTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: PCTheme.Radius.lg)
                .fill(Color.pcSurface)
                .pcModalShadow()
        )
        .padding(.horizontal, PCTheme.Spacing.md)
        .padding(.bottom, PCTheme.Spacing.sm)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
