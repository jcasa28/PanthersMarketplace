//
//  Post.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

<<<<<<< HEAD
=======
import Foundation

struct Post: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let price: Double
    let category: String // Changed to String to match database
    let userId: UUID // Changed from sellerId to match database column name
    let sellerName: String // This will come from the joined profiles table
    let status: String
    let createdAt: Date
    
    // Custom coding keys to map database columns to Swift properties
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case price
        case category
        case userId = "user_id"
        case sellerName = "username" // This comes from the joined profiles table
        case status
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        price: Double,
        category: String,
        userId: UUID,
        sellerName: String,
        status: String = "active",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.category = category
        self.userId = userId
        self.sellerName = sellerName
        self.status = status
        self.createdAt = createdAt
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

>>>>>>> origin/gabriel
