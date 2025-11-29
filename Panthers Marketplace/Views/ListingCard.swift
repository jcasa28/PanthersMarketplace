//
//  ListingCard.swift
//  Panthers Marketplace
//
//  Created by John Borrego on 10/22/25.
//

import SwiftUI
import Foundation

struct ListingCard: View {
    let listing: Post

    var body: some View {
       
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    // Placeholder since Post doesn't have image property yet
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text(listing.category)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        )
                }
                .frame(height: 270 * 0.6)
                
                VStack(spacing: 4) {
                    Text("$\(listing.price, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(.black)
                    Text(listing.title)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
                .padding(.vertical, 8)
            }
            .frame(width: 180, height: 270)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 5)
            .contentShape(Rectangle())
    }
}
#Preview {
    
}
