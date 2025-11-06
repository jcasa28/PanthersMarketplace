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
                
                if query.isEmpty {
                    Task {
                        await self.loadInitialPosts()
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
                // Load recent posts with pagination
                posts = try await SupabaseService.shared.fetchPosts(limit: pageSize, offset: offset)
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
            let posts = try await SupabaseService.shared.fetchPosts(limit: pageSize, offset: 0)
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
    
    func getSearchHistory() -> [String] {
        return searchHistory
    }
}
