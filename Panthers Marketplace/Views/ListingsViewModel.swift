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
        // (Optional) basic photo validation for now
        guard !draft.photos.isEmpty else { throw CreateError.failed }

        // TODO: upload draft.photos to Supabase Storage and get URLs

        // Convert Decimal -> Double for the Post initializer
        let priceDouble = NSDecimalNumber(decimal: draft.price).doubleValue

        // TEMP: until we have auth, use placeholder user/seller
        let placeholderUserId = UUID()
        let placeholderSellerName = "seller_placeholder"

        // Build exactly what Post expects (no extra labels!)
        let post = Post(
            title: draft.title,
            description: draft.description,
            price: priceDouble,
            category: draft.category,          // String (not enum)
            userId: placeholderUserId,
            sellerName: placeholderSellerName
            // status and createdAt use defaults
        )

        // Update local list so UI can reflect the new post immediately
        listings.insert(post, at: 0)
    }
}
