import SwiftUI

struct AssetThumbnailView: View {
    let assetID: String

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity.animation(.easeIn(duration: 0.15)))
            } else {
                Color.pcSkyLight
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(Color.pcTextSecondary.opacity(0.5))
                    }
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .task(id: assetID) {
            image = nil
            let expectedID = assetID
            let loaded = await ThumbnailLoader.shared.loadThumbnail(for: expectedID)
            if expectedID == assetID {
                image = loaded
            }
        }
    }
}
