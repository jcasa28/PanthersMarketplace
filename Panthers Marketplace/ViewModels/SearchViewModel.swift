//
//  SearchViewModel.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on 10/22/25.
//

import Foundation
import Combine

enum SearchError: Error, LocalizedError {
    case invalidPriceRange
    case networkError
    case invalidQuery
    case noResultsFound
    
    var errorDescription: String? {
        switch self {
        case .invalidPriceRange:
            return "Invalid price range. Maximum price must be greater than minimum price."
        case .networkError:
            return "Network error occurred while searching."
        case .invalidQuery:
            return "Invalid search query."
        case .noResultsFound:
            return "No results found for your search."
        }
    }
}

final class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var searchResults: [Post] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published var searchQuery = ""
    @Published private(set) var hasMorePages = true
    @Published var currentSort: SortOption = .newest  // NEW: Track current sort option
    
    // MARK: - Private Properties
    private var currentFilters = SearchFilters.empty()
    private var searchHistory: [String] = []
    private var searchCancellable: AnyCancellable?
    private var currentPage = 0
    private let pageSize = 20
    
    init() {
        setupDebouncedSearch()
        loadInitialPosts()
    }
    
    // MARK: - Debounced Search Setup
    private func setupDebouncedSearch() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                
                // Reset pagination when search query changes
                self.currentPage = 0
                self.hasMorePages = true
                
                // FIXED (Issue 4): Respect active filters when search is cleared
                // BUG: User filters by category, types search, then backspaces
                // BEFORE: Would show "Electronics" filter tag but display ALL listings
                // AFTER: Shows filtered Electronics listings even when search is empty
                if query.isEmpty {
                    // Check if any filters are active
                    if !self.currentFilters.hasActiveFilters() {
                        // No filters active - load all recent posts
                        Task {
                            await self.loadInitialPosts()
                        }
                    } else {
                        // Filters ARE active - perform search with empty query but keep filters
                        Task {
                            try? await self.performSearch(query: "", reset: true)
                        }
                    }
                } else {
                    Task {
                        try? await self.performSearch(query: query, reset: true)
                    }
                }
            }
    }
    
    // MARK: - Filter Methods
    func filterByCategory(_ category: ProductCategory?) {
        var newFilters = currentFilters
        newFilters.category = category
        applyFilters(newFilters)
    }
    
    func filterByPrice(min: Double?, max: Double?) {
        var newFilters = currentFilters
        newFilters.minPrice = min
        newFilters.maxPrice = max
        
        guard newFilters.isValidPriceRange() else {
            errorMessage = SearchError.invalidPriceRange.localizedDescription
            return
        }
        
        applyFilters(newFilters)
    }
    
    func filterByCampus(_ campus: Campus?) {
        var newFilters = currentFilters
        newFilters.campus = campus
        applyFilters(newFilters)
    }
    
    // MARK: - Sort Methods
    /// Changes the sort order and triggers a new search with the updated sorting
    /// This applies database-level sorting for efficient pagination
    func sortBy(_ option: SortOption) {
        currentSort = option
        currentFilters.sortOption = option
        
        // Reset pagination and perform new search with updated sort
        currentPage = 0
        hasMorePages = true
        Task {
            try? await performSearch(query: searchQuery, reset: true)
        }
    }
    
    func getCurrentSort() -> SortOption {
        return currentSort
    }
    
    // MARK: - Search Implementation
    private func applyFilters(_ filters: SearchFilters) {
        currentFilters = filters
        currentPage = 0  // Reset pagination when filters change
        hasMorePages = true
        Task {
            try? await performSearch(query: searchQuery, reset: true)
        }
    }
    
    @MainActor
    private func performSearch(query: String, reset: Bool = false) async throws {
        if reset {
            isLoading = true
            searchResults = []
            currentPage = 0
        } else {
            isLoadingMore = true
        }
        
        errorMessage = nil
        
        do {
            // Add to search history if not empty
            if !query.isEmpty && !searchHistory.contains(query) {
                searchHistory.append(query)
                if searchHistory.count > 10 {
                    searchHistory.removeFirst()
                }
            }
            
            // Calculate offset for pagination
            let offset = currentPage * pageSize
            
            // Perform actual database search with pagination
            let posts: [Post]
            if query.isEmpty && !currentFilters.hasActiveFilters() {
                // Load recent posts with pagination and current sort option
                posts = try await SupabaseService.shared.fetchPosts(limit: pageSize, offset: offset, sortOption: currentSort)
            } else {
                // Search with query and filters with pagination
                posts = try await SupabaseService.shared.searchPosts(query: query, filters: currentFilters, limit: pageSize, offset: offset)
            }
            
            // Check if we have more pages
            hasMorePages = posts.count == pageSize
            
            // Append or replace results
            if reset {
                searchResults = posts
            } else {
                searchResults.append(contentsOf: posts)
            }
            
            // Increment page for next load
            currentPage += 1
            
            if searchResults.isEmpty && (!query.isEmpty || currentFilters.hasActiveFilters()) {
                errorMessage = SearchError.noResultsFound.localizedDescription
            }
            
        } catch {
            print("❌ Search error: \(error)")
            errorMessage = SearchError.networkError.localizedDescription
        }
        
        isLoading = false
        isLoadingMore = false
    }
    
    // MARK: - Public Methods
    func loadMoreIfNeeded(currentPost: Post) {
        // Trigger load more when user reaches the last few items
        guard !isLoadingMore, hasMorePages else { return }
        
        let thresholdIndex = searchResults.index(searchResults.endIndex, offsetBy: -5)
        if let index = searchResults.firstIndex(where: { $0.id == currentPost.id }),
           index >= thresholdIndex {
            Task {
                try? await performSearch(query: searchQuery, reset: false)
            }
        }
    }
    
    func loadMore() {
        guard !isLoadingMore, hasMorePages else { return }
        Task {
            try? await performSearch(query: searchQuery, reset: false)
        }
    }
    
    // MARK: - Database Loading
    private func loadInitialPosts() {
        Task {
            await loadRecentPosts()
        }
    }
    
    @MainActor
    private func loadRecentPosts() async {
        isLoading = true
        currentPage = 0
        hasMorePages = true
        
        do {
            let posts = try await SupabaseService.shared.fetchPosts(limit: pageSize, offset: 0, sortOption: currentSort)
            searchResults = posts
            hasMorePages = posts.count == pageSize
            currentPage = 1
        } catch {
            print("❌ Failed to load initial posts: \(error)")
            errorMessage = "Failed to load posts"
        }
        
        isLoading = false
    }
    
    // MARK: - Public Methods
    func clearFilters() {
        currentFilters = SearchFilters.empty()
        currentPage = 0
        hasMorePages = true
        Task {
            try? await performSearch(query: searchQuery, reset: true)
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        errorMessage = nil
        currentPage = 0
        hasMorePages = true
    }
    
    func getCurrentFilters() -> SearchFilters {
        return currentFilters
    }
    
    // MARK: - Refresh Method
    
    /// Public method to refresh current search results
    /// Used when returning from detail view to show latest changes
    func refreshResults() async {
        do {
            try await performSearch(query: searchQuery, reset: true)
        } catch {
            print("Failed to refresh results: \(error)")
        }
    }
    
    func getSearchHistory() -> [String] {
        return searchHistory
    }

    
    // MARK: - State Synchronization (Backend Logic)
    // ============================================================
    // UI TEAM: Call these methods after CRUD operations to sync UI
    // These methods update the in-memory state without reloading from database
    // ============================================================
    
    /// Update a post in the search results after editing
    /// - Parameter updatedPost: The post with new values from database
    func updatePostInResults(_ updatedPost: Post) {
        if let index = searchResults.firstIndex(where: { $0.id == updatedPost.id }) {
            searchResults[index] = updatedPost
            print("✅ Backend: Updated post in search results: \(updatedPost.title)")
        } else {
            print("⚠️ Backend: Post not found in current results")
        }
    }
    
    /// Remove a post from search results after deletion
    /// - Parameter postId: ID of the deleted post
    func removePostFromResults(_ postId: UUID) {
        searchResults.removeAll { $0.id == postId }
        print("✅ Backend: Removed post from search results")
    }
    
    /// Add a new post to search results (appears at top)
    /// - Parameter newPost: The newly created post
    func addPostToResults(_ newPost: Post) {
        searchResults.insert(newPost, at: 0)
        print("✅ Backend: Added new post to search results: \(newPost.title)")
    }
    // ============================================================
}
