//
//  SearchFilters.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on 10/22/25
//

import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case electronics = "Electronics"
    case books = "Books"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case transportation = "Transportation"
    case other = "Other"
}

enum Campus: String, Codable {
    case engineering = "Engineering Campus"
    case mmc = "MMC Campus"
    case housing = "Housing"
    case bbc = "BBC Campus"
    case library = "Library"
    case business = "Business Campus"
    
    /// Maps UI-friendly names to database values that match the CHECK constraint
    var databaseValue: String {
        switch self {
        case .engineering:
            return "Engineering"
        case .mmc:
            return "MMC"
        case .housing:
            return "Housing"
        case .bbc:
            return "BBC"
        case .library:
            return "Library"
        case .business:
            return "Business"
        }
    }
}

// MARK: - Sort Options
enum SortOption: String, Codable, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case titleAZ = "Title: A-Z"
    case titleZA = "Title: Z-A"
    
    /// Returns the database column name to sort by
    var columnName: String {
        switch self {
        case .newest, .oldest:
            return "created_at"
        case .priceLowToHigh, .priceHighToLow:
            return "price"
        case .titleAZ, .titleZA:
            return "title"
        }
    }
    
    /// Returns whether sorting should be ascending or descending
    var isAscending: Bool {
        switch self {
        case .oldest, .priceLowToHigh, .titleAZ:
            return true
        case .newest, .priceHighToLow, .titleZA:
            return false
        }
    }
    
    /// Icon to display in UI (optional - UI team can customize)
    var iconName: String {
        switch self {
        case .newest:
            return "clock.arrow.circlepath"
        case .oldest:
            return "clock"
        case .priceLowToHigh:
            return "arrow.up.circle"
        case .priceHighToLow:
            return "arrow.down.circle"
        case .titleAZ:
            return "textformat.abc"
        case .titleZA:
            return "textformat.abc.dottedunderline"
        }
    }
}

struct SearchFilters {
    var category: ProductCategory?
    var minPrice: Double?
    var maxPrice: Double?
    var campus: Campus?
    var sortOption: SortOption = .newest  // Default: newest first
    
    init(category: ProductCategory? = nil,
         minPrice: Double? = nil,
         maxPrice: Double? = nil,
         campus: Campus? = nil,
         sortOption: SortOption = .newest) {
        self.category = category
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.campus = campus
        self.sortOption = sortOption
    }
    
    func isValidPriceRange() -> Bool {
        guard let min = minPrice, let max = maxPrice else {
            return true
        }
        return min >= 0 && max >= min
    }
    
    func hasActiveFilters() -> Bool {
        category != nil || minPrice != nil || maxPrice != nil || campus != nil
    }
    
    static func empty() -> SearchFilters {
        SearchFilters()
    }
}

// MARK: - Equatable
extension SearchFilters: Equatable {
    static func == (lhs: SearchFilters, rhs: SearchFilters) -> Bool {
        lhs.category == rhs.category &&
        lhs.minPrice == rhs.minPrice &&
        lhs.maxPrice == rhs.maxPrice &&
        lhs.campus == rhs.campus &&
        lhs.sortOption == rhs.sortOption
    }
}

// MARK: - Codable
extension SearchFilters: Codable {
    // Default Codable implementation is sufficient since all properties are Codable
}
