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
    let id: String  // Changed from UUID since Supabase sends UUID as string
    
    /// Username for display
    let username: String
    
    /// Optional contact information
    let contactInfo: String?
    
    /// User's campus location
    let location: String?
    
    /// User's role in the system
    let role: String  // Changed from enum to string to match raw data
    
    /// Account creation timestamp
    let createdAt: String  // Changed from Date to string to match raw format
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case contactInfo = "contact_info"
        case location
        case role
        case createdAt = "created_at"
    }
    
    // MARK: - Initializer
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id which might come as UUID or String
        if let uuidString = try? container.decode(String.self, forKey: .id) {
            id = uuidString
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.id],
                    debugDescription: "Invalid ID format"
                )
            )
        }
        
        // Decode required fields
        username = try container.decode(String.self, forKey: .username)
        role = try container.decode(String.self, forKey: .role)
        
        // Decode optional fields
        contactInfo = try container.decodeIfPresent(String.self, forKey: .contactInfo)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        
        // Handle created_at which might come in different formats
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = dateString
        } else {
            createdAt = "Unknown date"
        }
    }
    
    // Helper computed property to convert role string to enum if needed
    var userRole: UserRole? {
        UserRole(rawValue: role)
    }
}

// MARK: - UserRole Enum
enum UserRole: String, Codable {
    case student
    case buyer
    case seller
    case moderator
    case admin
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

