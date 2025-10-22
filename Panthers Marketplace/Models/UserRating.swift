//
//  UserRating.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on 10/22/25.
//

import Foundation

struct UserRating: Identifiable, Codable {
    let id: String
    let reviewerId: String
    let reviewedId: String
    let rating: Int
    let comment: String?
    let transactionId: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case reviewerId = "reviewer_id"
        case reviewedId = "reviewed_id"
        case rating
        case comment
        case transactionId = "transaction_id"
        case createdAt = "created_at"
    }
}
