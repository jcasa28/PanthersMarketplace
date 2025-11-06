//
//  Message.swift
//  Panthers Marketplace
//

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let postId: UUID
    let message: String
    let senderName: String
    let createdAt: Date
    
    var isFromCurrentUser: Bool {
        // This will be set by the ViewModel based on the current test user
        false
    }
}
