//
//  ProfileViewModel.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on 10/22/25.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
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
            // TODO: Implement Supabase query for user profile
            // profiles table where id matches current user
            await loadUserStats()
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
    }
    
    /// Loads user statistics
    private func loadUserStats() async {
        guard !isLoadingStats else { return }
        isLoadingStats = true
        defer { isLoadingStats = false }
        
        do {
            // TODO: Implement Supabase queries for stats
            // Count queries for:
            // 1. Posts where user_id matches
            // 2. Saved items where user_id matches
            // 3. Messages (unique conversations) where user is sender or receiver
            // 4. Completed transactions where user is buyer or seller
            stats = .empty
        } catch {
            errorMessage = "Failed to load stats: \(error.localizedDescription)"
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
