//
//  ProfileViewModel.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on 10/22/25.
//

import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    // Local preview for the current user's profile screen ONLY after upload.
    @Published var profileImage: UIImage? = nil

    // Signed URL to the current user's avatar for display on profile screen.
    @Published private(set) var avatarURL: URL? = nil

    // Token to force UserAvatarView instances to reload after uploads.
    @Published var avatarReloadToken: Int = 0

    // New: Saving state and error for avatar updates
    @Published private(set) var isSavingProfileImage: Bool = false
    @Published private(set) var saveError: String? = nil

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

    // MARK: - Avatar Saving

    func updateProfileImage(_ image: UIImage) {
        // Retain for compatibility if other parts call this
        self.profileImage = image
    }

    /// Uploads image, updates profiles.avatar_path, updates local preview and signed URL.
    func saveProfileImage(_ image: UIImage) async {
        guard !isSavingProfileImage else {
            print("ℹ️ [ProfileVM] saveProfileImage ignored, already in progress")
            return
        }
        isSavingProfileImage = true
        saveError = nil

        print("🔄 [ProfileVM] Starting saveProfileImage flow")

        do {
            // 1) Get current authenticated user
            guard let currentUser = try await SupabaseService.shared.getCurrentUser() else {
                print("❌ [ProfileVM] No authenticated user found")
                saveError = "No authenticated user found."
                isSavingProfileImage = false
                return
            }

            guard let userUUID = UUID(uuidString: currentUser.id) else {
                print("❌ [ProfileVM] Invalid user ID format: \(currentUser.id)")
                saveError = "Invalid user ID."
                isSavingProfileImage = false
                return
            }
            print("ℹ️ [ProfileVM] Current user UUID: \(userUUID)")

            // 2) Upload to Storage (unique filename)
            let storagePath = try await SupabaseService.shared.uploadProfileImage(image: image, userId: userUUID)
            print("✅ [ProfileVM] Image uploaded, storagePath='\(storagePath)'")

            // 3) Update profiles.avatar_path
            try await SupabaseService.shared.updateProfileAvatarPath(userId: userUUID, avatarPath: storagePath)
            print("✅ [ProfileVM] profiles.avatar_path updated")

            // 4) Update local UI image (preview for the profile screen only)
            self.profileImage = image
            print("✅ [ProfileVM] Local profileImage updated")

            // 5) Fetch a fresh signed URL for display
            self.avatarURL = try? await SupabaseService.shared.getUserAvatarURL(userId: userUUID)
            print("✅ [ProfileVM] avatarURL refreshed for profile view")

            // 6) Bump reload token so any UserAvatarView instances refresh
            self.avatarReloadToken &+= 1

            // 7) Optionally refresh user profile basics (if needed)
            await loadUserProfileBasicsOnly()

        } catch let error as PostgrestError {
            print("❌ [ProfileVM] PostgrestError during saveProfileImage: \(error.message)")
            if let hint = error.hint { print("💡 [ProfileVM] Hint: \(hint)") }
            saveError = error.message
        } catch {
            print("❌ [ProfileVM] Unknown error during saveProfileImage: \(error.localizedDescription)")
            saveError = error.localizedDescription
        }

        isSavingProfileImage = false
        print("🏁 [ProfileVM] saveProfileImage flow finished")
    }

    // MARK: - Public Methods

    /// Refreshes all user data
    func refreshProfile() async {
        await loadUserProfile()
        await loadUserStats()
        await loadRatings()
    }

    /// Loads user's listed items
    func loadListings() async {
        guard !isLoadingListings else { return }
        isLoadingListings = true
        defer { isLoadingListings = false }

        do {
            guard let userIdString = user?.id,
                  let userId = UUID(uuidString: userIdString) else {
                print("⚠️ Warning: Cannot load listings without valid user ID (user?.id = \(String(describing: user?.id)))")
                listedItems = []
                return
            }
            print("DEBUG: Using userId for listings: \(userId.uuidString)")
            listedItems = try await SupabaseService.shared.fetchUserPosts(userId: userId)
            print("DEBUG: listedItems loaded: \(listedItems.count)")
        } catch {
            errorMessage = "Failed to load listings: \(error.localizedDescription)"
            listedItems = []
        }
    }

    /// Loads user's saved items
    func loadSavedItems() async {
        guard !isLoadingSaved else { return }
        isLoadingSaved = true
        defer { isLoadingSaved = false }

        do {
            guard let userIdString = user?.id, let userId = UUID(uuidString: userIdString) else {
                print("⚠️ Warning: Cannot load saved items without valid user ID (user?.id = \(String(describing: user?.id)))")
                savedItems = []
                return
            }
            print("DEBUG: Using userId for saved items: \(userId.uuidString)")
            savedItems = try await SupabaseService.shared.fetchSavedItems(userId: userId)
            print("DEBUG: savedItems loaded: \(savedItems.count)")
        } catch {
            errorMessage = "Failed to load saved items: \(error.localizedDescription)"
            savedItems = []
        }
    }

    /// Loads user's ratings and reviews
    func loadRatings() async {
        guard !isLoadingRatings else { return }
        isLoadingRatings = true
        defer { isLoadingRatings = false }

        do {
            // TODO: Implement Supabase query for ratings
            ratings = []
            updateAverageRating()
        } catch {
            errorMessage = "Failed to load ratings: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Loads the user's profile data and avatarURL
    private func loadUserProfile() async {
        guard !isLoadingProfile else { return }
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        do {
            user = try await SupabaseService.shared.getCurrentUser()

            if let user = user {
                print("✅ Loaded user profile: \(user.username)")
                // Fetch avatar URL for current user
                if let userUUID = UUID(uuidString: user.id) {
                    self.avatarURL = try? await SupabaseService.shared.getUserAvatarURL(userId: userUUID)
                } else {
                    self.avatarURL = nil
                }
                // After loading user, load their stats and listings
                await loadUserStats()
                await loadListings()
                await loadSavedItems()
            } else {
                print("⚠️ No authenticated user found - user needs to log in")
                errorMessage = "No user logged in. Authentication required."
                self.avatarURL = nil
            }
        } catch {
            let errorString = "\(error)"
            if !errorString.contains("sessionMissing") {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
                print("❌ Error loading user profile: \(error)")
            } else {
                errorMessage = "No user logged in. Authentication required."
                print("ℹ️ No active session - user needs to authenticate")
            }
            self.avatarURL = nil
        }
    }

    /// Load only the user row (no stats/listings) to update small bits quickly
    private func loadUserProfileBasicsOnly() async {
        do {
            user = try await SupabaseService.shared.getCurrentUser()
            if let user = user, let userUUID = UUID(uuidString: user.id) {
                self.avatarURL = try? await SupabaseService.shared.getUserAvatarURL(userId: userUUID)
            }
        } catch {
            print("❌ Error refreshing user profile basics: \(error)")
        }
    }

    /// Loads user statistics
    private func loadUserStats() async {
        guard !isLoadingStats else { return }
        isLoadingStats = true
        defer { isLoadingStats = false }

        do {
            guard let userIdString = user?.id,
                  let userId = UUID(uuidString: userIdString) else {
                print("⚠️ Warning: Cannot load stats without valid user ID")
                stats = .empty
                return
            }

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
