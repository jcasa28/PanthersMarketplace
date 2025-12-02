//
//  ListingCard.swift
//  Panthers Marketplace
//
//  Created by John Borrego on 10/22/25.
//

import SwiftUI



struct ListingCard: View {
    let listing: Post

    // MARK: - Category → Image
    private var imageNameForCategory: String {
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
            return "listing_other"
        }
    }

    var body: some View {
        
        VStack(alignment: .leading) {
            
            // --- Image Section ---
            VStack {
                Image(imageNameForCategory)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 168)
                    .clipped()
                    .aspectRatio(contentMode: .fill)
            }
            .offset(y: -38)
            
            // --- Text Section ---
            VStack(alignment: .leading) {
                Text("$\(listing.price, specifier: "%.2f")")
                    .foregroundColor(Color(red: 25/255, green: 40/255, blue: 60/255))
                    .padding(.bottom, 2)
                    .font(.system(size: 20))
                
                Text(listing.title)
                    .font(.system(size: 17))
            }
            .offset(y: -30)
            .padding(.leading)
        }
        .frame(width: 180, height: 280)
        .background(Color(.white))
        .cornerRadius(20)
        .shadow(radius: 2)
        .padding(.bottom)
    }
}

#Preview {
    
}
