//
//  ProfileViewModel.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on 10/22/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileImage: UIImage? = nil   // ← shared profile picture
        
        func updateProfileImage(_ image: UIImage) {
            self.profileImage = image
            
        }
    /// The current user's profile data
    @Published private(set) var user: User?
   
   
    
    /// The user's activity statistics
    @Published private(set) var stats: UserStats = .empty
    
    /// User's listed items/posts
    @Published private(set) var listedItems: [Post] = []
    
    /// User's saved items
    @Published private(set) var savedItems: [Post] = []
    
    /// User's received ratings and reviews
    @Published private(set) var ratings: [UserRating] = []
    
    /// Average rating score
    @Published private(set) var averageRating: Double = 0.0
    
    /// Loading states
    @Published private(set) var isLoadingProfile = false
    @Published private(set) var isLoadingStats = false
    @Published private(set) var isLoadingListings = false
    @Published private(set) var isLoadingSaved = false
    @Published private(set) var isLoadingRatings = false
    
    /// Error message if any operation fails
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        Task {
            await loadUserProfile()
        }
    }
    
    // MARK: - Public Methods
    
    /// Refreshes all user data
    func refreshProfile() async {
        await loadUserProfile()
        await loadUserStats()
        await loadListings()
        await loadSavedItems()
        await loadRatings()
    }
    
    /// Loads user's listed items
    func loadListings() async {
        guard !isLoadingListings else { return }
        isLoadingListings = true
        defer { isLoadingListings = false }
        
        do {
            // TODO: Implement Supabase query for user's posts
            // posts table where user_id matches current user
            listedItems = []
        } catch {
            errorMessage = "Failed to load listings: \(error.localizedDescription)"
        }
    }
    
    /// Loads user's saved items
    func loadSavedItems() async {
        guard !isLoadingSaved else { return }
        isLoadingSaved = true
        defer { isLoadingSaved = false }
        
        do {
            // TODO: Implement Supabase query for saved items
            // Join saved_items with posts where user_id matches
            savedItems = []
        } catch {
            errorMessage = "Failed to load saved items: \(error.localizedDescription)"
        }
    }
    
    /// Loads user's ratings and reviews
    func loadRatings() async {
        guard !isLoadingRatings else { return }
        isLoadingRatings = true
        defer { isLoadingRatings = false }
        
        do {
            // TODO: Implement Supabase query for ratings
            // reviews table where reviewed_id matches current user
            ratings = []
            updateAverageRating()
        } catch {
            errorMessage = "Failed to load ratings: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads the user's profile data
    private func loadUserProfile() async {
        guard !isLoadingProfile else { return }
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        
        do {
            // Fetch current authenticated user's profile from Supabase
            user = try await SupabaseService.shared.getCurrentUser()
            
            if let user = user {
                print("✅ Loaded user profile: \(user.username)")
                // After loading user, load their stats
                await loadUserStats()
            } else {
                print("⚠️ No authenticated user found - user needs to log in")
                errorMessage = "No user logged in. Authentication required."
            }
        } catch {
            // Only show error if it's not a session missing error
            let errorString = "\(error)"
            if !errorString.contains("sessionMissing") {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
                print("❌ Error loading user profile: \(error)")
            } else {
                errorMessage = "No user logged in. Authentication required."
                print("ℹ️ No active session - user needs to authenticate")
            }
        }
    }
    
    /// Loads user statistics
    private func loadUserStats() async {
        guard !isLoadingStats else { return }
        isLoadingStats = true
        defer { isLoadingStats = false }
        
        do {
            // Get current user ID from the loaded user profile
            guard let userIdString = user?.id,
                  let userId = UUID(uuidString: userIdString) else {
                print("⚠️ Warning: Cannot load stats without valid user ID")
                stats = .empty
                return
            }
            
            // Fetch actual stats from Supabase
            stats = try await SupabaseService.shared.fetchUserStats(userId: userId)
            print("✅ Loaded user stats: \(stats.listedItemsCount) listed, \(stats.savedItemsCount) saved, \(stats.chatsCount) chats")
            
        } catch {
            errorMessage = "Failed to load stats: \(error.localizedDescription)"
            print("❌ Error loading user stats: \(error)")
            stats = .empty
        }
    }
    
    private func updateAverageRating() {
        guard !ratings.isEmpty else {
            averageRating = 0.0
            return
        }
        let total = ratings.reduce(0) { $0 + $1.rating }
        averageRating = Double(total) / Double(ratings.count)
    }
}

// MARK: - Error Handling
extension ProfileViewModel {
    enum ProfileError: LocalizedError {
        case failedToLoadProfile
        case failedToLoadStats
        case failedToLoadListings
        case failedToLoadSaved
        case failedToLoadRatings
        
        var errorDescription: String? {
            switch self {
            case .failedToLoadProfile:
                return "Could not load user profile"
            case .failedToLoadStats:
                return "Could not load user statistics"
            case .failedToLoadListings:
                return "Could not load user listings"
            case .failedToLoadSaved:
                return "Could not load saved items"
            case .failedToLoadRatings:
                return "Could not load user ratings"
            }
        }
    }
}

// MARK: - Rating Statistics
extension ProfileViewModel {
    var ratingStats: (average: Double, count: Int) {
        (averageRating, ratings.count)
    }
    
    var hasRatings: Bool {
        !ratings.isEmpty
    }
}
