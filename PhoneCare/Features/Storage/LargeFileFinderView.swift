import SwiftUI
import Photos
import QuickLook

/// Displays large videos from the photo library sorted by size,
/// with file size info and QuickLook preview support.
struct LargeFileFinderView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager

    let largeVideoIDs: [String]

    @State private var files: [LargeFileInfo] = []
    @State private var isLoading = true
    @State private var selectedFileURL: URL?
    @State private var totalSize: Int64 = 0

    var body: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
            if isLoading {
                ProgressView("Finding large files…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PCTheme.Spacing.xl)
            } else if files.isEmpty {
                emptyState
            } else {
                header
                fileList
            }
        }
        .task {
            await loadFiles()
        }
        .background(Color.pcBackground)
        .navigationTitle("Large Files")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("screen.largeFileFinder")
    }

    // MARK: - Header

    private var header: some View {
        CardView {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .font(.title3)
                    .foregroundStyle(Color.pcAccent)
                    .voiceOverHidden()

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(files.count) large files found")
                        .typography(.headline)
                    Text("\(formattedSize(totalSize)) could be freed")
                        .typography(.subheadline, color: .pcTextSecondary)
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - File List

    private var fileList: some View {
        VStack(spacing: PCTheme.Spacing.sm) {
            ForEach(files) { file in
                Button {
                    selectedFileURL = file.fileURL
                } label: {
                    HStack(spacing: PCTheme.Spacing.md) {
                        // Thumbnail
                        if let thumbnail = file.thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: PCTheme.Radius.sm))
                                .voiceOverHidden()
                        } else {
                            RoundedRectangle(cornerRadius: PCTheme.Radius.sm)
                                .fill(Color.pcSurface)
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: "video.fill")
                                        .foregroundStyle(Color.pcTextSecondary)
                                }
                                .voiceOverHidden()
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.displayName)
                                .typography(.subheadline)
                                .lineLimit(1)
                            Text(file.dateText)
                                .typography(.caption, color: .pcTextSecondary)
                        }

                        Spacer()

                        Text(file.sizeText)
                            .typography(.subheadline, color: .pcAccent)
                            .fontWeight(.semibold)
                    }
                    .padding(PCTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: PCTheme.Radius.md)
                            .fill(Color.pcSurface)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(file.displayName), \(file.sizeText), \(file.dateText)")
                .accessibilityHint("Double tap to preview")
            }
        }
        .quickLookPreview($selectedFileURL)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: PCTheme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.pcAccent)
                .voiceOverHidden()
            Text("No large files found")
                .typography(.headline)
            Text("Your storage is looking good — no videos over 50 MB.")
                .typography(.subheadline, color: .pcTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PCTheme.Spacing.xl)
    }

    // MARK: - Data Loading

    private func loadFiles() async {
        let idsFetched: PHFetchResult<PHAsset>
        if largeVideoIDs.isEmpty {
            // Scan all videos from library when no pre-computed IDs are supplied
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "duration", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            idsFetched = PHAsset.fetchAssets(with: options)
        } else {
            idsFetched = PHAsset.fetchAssets(withLocalIdentifiers: largeVideoIDs, options: nil)
        }

        guard idsFetched.count > 0 else {
            isLoading = false
            return
        }

        let fetchResult = idsFetched
        var loaded: [LargeFileInfo] = []

        let imageManager = PHCachingImageManager()
        let thumbOptions = PHImageRequestOptions()
        thumbOptions.isSynchronous = true
        thumbOptions.deliveryMode = .fastFormat

        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            let size = resources.reduce(Int64(0)) { total, resource in
                total + (resource.value(forKey: "fileSize") as? Int64 ?? 0)
            }

            var thumbnail: UIImage?
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 112, height: 112),
                contentMode: .aspectFill,
                options: thumbOptions
            ) { image, _ in
                thumbnail = image
            }

            loaded.append(LargeFileInfo(
                id: asset.localIdentifier,
                estimatedSize: size > 0 ? size : Int64(asset.duration * 5_000_000),
                creationDate: asset.creationDate,
                duration: asset.duration,
                thumbnail: thumbnail,
                fileURL: nil
            ))
        }

        files = loaded.sorted { $0.estimatedSize > $1.estimatedSize }
        totalSize = files.reduce(0) { $0 + $1.estimatedSize }
        isLoading = false
    }

    private func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Model

struct LargeFileInfo: Identifiable {
    let id: String
    let estimatedSize: Int64
    let creationDate: Date?
    let duration: TimeInterval
    let thumbnail: UIImage?
    let fileURL: URL?

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: estimatedSize, countStyle: .file)
    }

    var dateText: String {
        guard let date = creationDate else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var displayName: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "Video (\(minutes)m \(seconds)s)"
        }
        return "Video (\(seconds)s)"
    }
}
