import SwiftUI
import Observation
import Foundation

@MainActor
@Observable
final class ListingsViewModel {
    private(set) var listings: [Post] = []

    struct ListingDraft {
        var photos: [UIImage]
        var title: String
        var price: Decimal
        var category: String
        var condition: String
        var description: String
        var location: String
    }

    enum CreateError: Error { case failed }

    func createListing(_ draft: ListingDraft) async throws {
        try await Task.sleep(nanoseconds: 900_000_000)

        let datas = draft.photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        guard !datas.isEmpty else { throw CreateError.failed }

        let post = Post(
            title: draft.title,
            description: draft.description,
            price: Double(truncating: draft.price as NSNumber),
            category: ProductCategory(rawValue: draft.category) ?? .other,
            campus: .modesto, // TODO: set proper campus
            sellerId: UUID(), // TODO: set proper sellerId
            sellerName: "seller_name_placeholder", // TODO: set proper sellerName
            imageUrls: [], // TODO: supply URLs after upload
            isAvailable: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        listings.insert(post, at: 0)
    }
}

#if DEBUG
extension ListingsViewModel {
    static func makePreview() -> ListingsViewModel {
        let vm = ListingsViewModel()
        vm.listings = []
        return vm
    }
}
#endif
