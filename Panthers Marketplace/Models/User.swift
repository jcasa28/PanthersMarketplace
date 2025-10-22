//
//  User.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import Foundation

struct User: Identifiable, Codable {
    // MARK: - Properties
    
    /// Unique identifier for the user
    let id: String
    
    /// Username for display
    let username: String
    
    /// Optional contact information
    let contactInfo: String?
    
    /// User's campus location
    let location: String?
    
    /// Account creation timestamp
    let createdAt: Date
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case contactInfo = "contact_info"
        case location
        case createdAt = "created_at"
    }
}

// MARK: - Equatable
extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

