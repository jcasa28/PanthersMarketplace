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
    
    // Pick an image based on the category text coming from the DB
       private var imageNameForCategory: String? {
           switch listing.category.lowercased() {
           case "electronics":
               return "listing_electronics"
           case "books":
               return "listing_books"
           case "furniture":
               return "listing_furniture"
           case "clothing":
               return "listing_clothing"
           case "transportation":
               return "listing_transportation"
           default:
               return "listing_other"   // or nil if you don’t have this one
           }
       }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    if let imageNameForCategory {
                        Image(imageNameForCategory)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        // Fallback placeholder if something goes wrong
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
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
                }
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
