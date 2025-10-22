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
    @Published private(set) var errorMessage: String?
    @Published var searchQuery = ""
    
    // MARK: - Private Properties
    private var currentFilters = SearchFilters.empty()
    private var searchHistory: [String] = []
    private var searchCancellable: AnyCancellable?
    private var allPosts: [Post] = [] // Mock data storage
    
    init() {
        setupDebouncedSearch()
        loadMockData()
    }
    
    // MARK: - Debounced Search Setup
    private func setupDebouncedSearch() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard !query.isEmpty else {
                    self?.searchResults = []
                    return
                }
                
                Task {
                    try? await self?.performSearch(query: query)
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
        Task {
            try? await performSearch(query: searchQuery)
        }
    }
    
    @MainActor
    private func performSearch(query: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Add to search history if not empty
            if !query.isEmpty && !searchHistory.contains(query) {
                searchHistory.append(query)
                if searchHistory.count > 10 {
                    searchHistory.removeFirst()
                }
            }
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Filter posts based on query and current filters
            let filteredPosts = allPosts.filter { post in
                matchesQuery(post: post, query: query) && matchesFilters(post: post)
            }
            
            searchResults = filteredPosts
            
            if filteredPosts.isEmpty && !query.isEmpty {
                errorMessage = SearchError.noResultsFound.localizedDescription
            }
            
        } catch {
            errorMessage = SearchError.networkError.localizedDescription
        }
        
        isLoading = false
    }
    
    private func matchesQuery(post: Post, query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        return post.title.lowercased().contains(lowercaseQuery) ||
               post.description.lowercased().contains(lowercaseQuery) ||
               post.sellerName.lowercased().contains(lowercaseQuery)
    }
    
    private func matchesFilters(post: Post) -> Bool {
        // Category filter
        if let category = currentFilters.category, post.category != category {
            return false
        }
        
        // Price filter
        if let minPrice = currentFilters.minPrice, post.price < minPrice {
            return false
        }
        
        if let maxPrice = currentFilters.maxPrice, post.price > maxPrice {
            return false
        }
        
        // Campus filter
        if let campus = currentFilters.campus, post.campus != campus {
            return false
        }
        
        return true
    }
    
    // MARK: - Public Methods
    func clearFilters() {
        currentFilters = SearchFilters.empty()
        Task {
            try? await performSearch(query: searchQuery)
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        errorMessage = nil
    }
    
    func getCurrentFilters() -> SearchFilters {
        return currentFilters
    }
    
    func getSearchHistory() -> [String] {
        return searchHistory
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        // This would typically load from a database or API
        allPosts = [
            Post(
                title: "iPhone 14 Pro",
                description: "Like new iPhone 14 Pro, 256GB",
                price: 800.0,
                category: ProductCategory.electronics,
                campus: Campus.biscayne,
                sellerId: UUID(),
                sellerName: "John Doe"
            ),
            Post(
                title: "Calculus Textbook",
                description: "Used calculus textbook in good condition",
                price: 150.0,
                category: ProductCategory.books,
                campus: Campus.engineering,
                sellerId: UUID(),
                sellerName: "Jane Smith"
            )
        ]
    }
}
