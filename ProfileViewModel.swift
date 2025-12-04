// In ProfileViewModel.swift, inside the class
func resetForLogout() {
    // Clear all avatar and profile-related cached state
    profileImage = nil
    avatarURL = nil
    avatarReloadToken = 0
    
    user = nil
    stats = .empty
    listedItems = []
    savedItems = []
    ratings = []
    averageRating = 0.0
    
    isLoadingProfile = false
    isLoadingStats = false
    isLoadingListings = false
    isLoadingSaved = false
    isLoadingRatings = false
    errorMessage = nil
}
