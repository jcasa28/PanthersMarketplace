import SwiftUI
import Observation
import Foundation

@MainActor
@Observable
final class ListingsViewModel {
    private(set) var listings: [Post] = []
    private var authVM: AuthViewModel?  // Reference to auth

    struct ListingDraft {
        var photos: [UIImage]
        var title: String
        var price: Decimal
        var category: String
        var condition: String
        var description: String
        var location: String
    }

    enum CreateError: Error {
        case failed
        case notAuthenticated
        case uploadFailed
    }
    
    enum UpdateError: Error {
        case notAuthenticated
        case notAuthorized  // User doesn't own this post
        case updateFailed
    }
    
    enum DeleteError: Error {
        case notAuthenticated
        case deleteFailed
    }
    
    // Add init to accept auth
    init(authVM: AuthViewModel? = nil) {
        self.authVM = authVM
    }

    func createListing(_ draft: ListingDraft) async throws {
        // Validate photos
        guard !draft.photos.isEmpty else { throw CreateError.failed }

        // Get authenticated user ID
        guard let userId = authVM?.userId else {
            print("❌ User not authenticated")
            throw CreateError.notAuthenticated
        }

        // TODO: upload draft.photos to Supabase Storage and get URLs
        let imageUrls: [String] = []  // Placeholder for now

        // Convert Decimal -> Double for the Post initializer
        let priceDouble = NSDecimalNumber(decimal: draft.price).doubleValue

        // Create post in database with REAL user ID
        let createdPost = try await SupabaseService.shared.createPost(
            title: draft.title,
            description: draft.description,
            price: priceDouble,
            category: draft.category,
            userId: userId,
            campusLocation: draft.location,
            imageUrls: imageUrls
        )

        // Update local list so UI can reflect the new post immediately
        listings.insert(createdPost, at: 0)
        
        print("✅ Listing created successfully: \(createdPost.title)")
    }
    
    func updateListing(
        postId: UUID,
        title: String? = nil,
        description: String? = nil,
        price: Decimal? = nil,
        category: String? = nil,
        location: String? = nil,
        status: String? = nil
    ) async throws -> Post {
        // Get authenticated user ID
        guard let userId = authVM?.userId else {
            print("❌ User not authenticated")
            throw UpdateError.notAuthenticated
        }
        
        // Convert Decimal to Double if price is provided
        let priceDouble = price.map { NSDecimalNumber(decimal: $0).doubleValue }
        
        // Update post in database
        let updatedPost = try await SupabaseService.shared.updatePost(
            id: postId,
            title: title,
            description: description,
            price: priceDouble,
            category: category,
            campusLocation: location,
            status: status
        )
        
        // Update in local listings array if it exists
        if let index = listings.firstIndex(where: { $0.id == postId }) {
            listings[index] = updatedPost
        }
        
        print("✅ Listing updated successfully: \(updatedPost.title)")
        return updatedPost
    }
    
    func deleteListing(postId: UUID) async throws {
        // Check user is authenticated
        guard let userId = authVM?.userId else {
            print("❌ User not authenticated")
            throw DeleteError.notAuthenticated
        }
        
        // Soft delete in database (marks status as "hidden")
        // Note: Uses "hidden" instead of "deleted" to match database constraint
        try await SupabaseService.shared.deletePost(id: postId)
        
        // Remove from local listings array
        listings.removeAll { $0.id == postId }
        
        print("✅ Listing deleted successfully")
    }
}
