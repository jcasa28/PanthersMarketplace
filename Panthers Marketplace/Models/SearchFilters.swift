//
//  SearchFilters.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on 10/22/25
//

import Foundation

enum ProductCategory: String, Codable {
    case electronics = "Electronics"
    case books = "Books"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case transportation = "Transportation"
    case other = "Other"
}

enum Campus: String, Codable {
    case modesto = "Modesto"
    case biscayne = "Biscayne"
    case engineering = "Engineering"
}

struct SearchFilters {
    var category: ProductCategory?
    var minPrice: Double?
    var maxPrice: Double?
    var campus: Campus?
    
    init(category: ProductCategory? = nil,
         minPrice: Double? = nil,
         maxPrice: Double? = nil,
         campus: Campus? = nil) {
        self.category = category
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.campus = campus
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
        lhs.campus == rhs.campus
    }
}

// MARK: - Codable
extension SearchFilters: Codable {
    // Default Codable implementation is sufficient since all properties are Codable
}
