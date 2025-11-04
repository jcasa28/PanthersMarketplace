import SwiftUI
import Observation

struct Post: Identifiable, Hashable {
    let id: UUID
    var title: String
    var price: Decimal
    var category: String
    var condition: String
    var description: String
    var location: String
    var imageDatas: [Data]
    var createdAt: Date
}

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
            id: UUID(),
            title: draft.title,
            price: draft.price,
            category: draft.category,
            condition: draft.condition,
            description: draft.description,
            location: draft.location,
            imageDatas: datas,
            createdAt: Date()
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

