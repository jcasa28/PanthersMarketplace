//
//  Listing.swift
//  Panthers Marketplace
//
//  Created by Cesar Calzadilla on 11/5/25.
//

import Foundation

struct Listing: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let price: Double
    let category: String
    let imageName: String
}
