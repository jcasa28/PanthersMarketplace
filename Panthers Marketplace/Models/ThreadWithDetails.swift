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
    
    var lastMessagePreview: String?
    var lastMessageTime: Date?
    
    // Per-user avatar timestamp for cache busting
    var otherPersonAvatarUpdatedAt: Date?
    
    // New: Storage path to other person's avatar (e.g., "users/<uuid>/profile-xxx.jpg")
    var otherPersonAvatarPath: String?
}

