//
//  UserStats.swift
//  Panthers Marketplace
//
//  Created by im-gabriel-sosa on   10/22/25.
//

import Foundation

struct UserStats: Codable {
    // MARK: - Properties
    
    /// Number of items user has listed
    let listedItemsCount: Int
    
    /// Number of items user has saved
    let savedItemsCount: Int
    
    /// Number of active chat threads
    let chatsCount: Int
    
    /// Number of completed transactions
    let completedTransactions: Int
    
    /// User's overall earnings
    let totalEarnings: Double
    
    // MARK: - Computed Properties
    
    /// Indicates if user has any activity
    var hasActivity: Bool {
        listedItemsCount > 0 || savedItemsCount > 0 || chatsCount > 0 || completedTransactions > 0
    }
    
    // MARK: - Initialization
    
    init(listedItemsCount: Int = 0,
         savedItemsCount: Int = 0,
         chatsCount: Int = 0,
         completedTransactions: Int = 0,
         totalEarnings: Double = 0.0) {
        self.listedItemsCount = listedItemsCount
        self.savedItemsCount = savedItemsCount
        self.chatsCount = chatsCount
        self.completedTransactions = completedTransactions
        self.totalEarnings = totalEarnings
    }
}

// MARK: - Equatable
extension UserStats: Equatable {}

// MARK: - Default Value
extension UserStats {
    /// Creates an empty stats object
    static var empty: UserStats {
        UserStats()
    }
}
