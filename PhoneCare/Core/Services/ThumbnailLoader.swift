import UIKit
import Photos

@MainActor
final class ThumbnailLoader {

    static let shared = ThumbnailLoader()

    private let imageManager = PHCachingImageManager()
    private let cache = NSCache<NSString, UIImage>()
    private let targetSize = CGSize(width: 240, height: 240)
    private let requestOptions: PHImageRequestOptions

    private init() {
        cache.countLimit = 500
        cache.totalCostLimit = 50 * 1024 * 1024

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        requestOptions = options
    }

    func loadThumbnail(for assetID: String) async -> UIImage? {
        if let cached = cache.object(forKey: assetID as NSString) {
            return cached
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = assets.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image {
                    let cost = image.cgImage.map { $0.width * $0.height * 4 } ?? 0
                    self.cache.setObject(image, forKey: assetID as NSString, cost: cost)
                }
                continuation.resume(returning: image)
            }
        }
    }
}
