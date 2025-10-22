//
//  Post.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import Foundation

struct Post: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let price: Double
    let category: ProductCategory
    let campus: Campus
    let sellerId: UUID
    let sellerName: String
    let imageUrls: [String]
    let isAvailable: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        price: Double,
        category: ProductCategory,
        campus: Campus,
        sellerId: UUID,
        sellerName: String,
        imageUrls: [String] = [],
        isAvailable: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.category = category
        self.campus = campus
        self.sellerId = sellerId
        self.sellerName = sellerName
        self.imageUrls = imageUrls
        self.isAvailable = isAvailable
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Equatable
extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Post: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

