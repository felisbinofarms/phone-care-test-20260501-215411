import SwiftUI

struct PhotoGridView: View {
    let photoIDs: [String]
    let selectedIDs: Set<String>
    var onToggle: ((String) -> Void)?
    var onLongPress: ((String) -> Void)?

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 4)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(photoIDs, id: \.self) { photoID in
                photoThumbnail(id: photoID)
            }
        }
    }

    @ViewBuilder
    private func photoThumbnail(id: String) -> some View {
        let isSelected = selectedIDs.contains(id)

        ZStack(alignment: .topTrailing) {
            AssetThumbnailView(assetID: id)

            // Selection checkmark
            if isSelected {
                ZStack {
                    Circle()
                        .fill(Color.pcAccent)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(4)
                .transition(.scale.combined(with: .opacity))
            } else {
                Circle()
                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .padding(4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                onToggle?(id)
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress?(id)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to toggle selection. Long press to preview.")
    }
}
