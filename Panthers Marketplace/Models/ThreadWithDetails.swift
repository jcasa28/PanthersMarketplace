//
//  ThreadWithDetails.swift
//  Panthers Marketplace
//

import Foundation

struct ThreadWithDetails: Identifiable, Codable {
    let id: UUID
    let postId: UUID
    let postTitle: String
    let buyerId: UUID
    let sellerId: UUID
    let otherPersonName: String
    let otherPersonId: UUID
    let createdAt: Date
    
    // Optional: Last message preview (can be added later)
    var lastMessagePreview: String?
    var lastMessageTime: Date?
}
