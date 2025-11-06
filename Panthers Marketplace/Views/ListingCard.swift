//
//  ListingCard.swift
//  Panthers Marketplace
//
//  Created by John Borrego on 10/22/25.
//

import SwiftUI
import Foundation

struct ListingCard: View {
    let listing: Listing

    var body: some View {
       
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    Image(listing.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .frame(height: 270 * 0.6)
                
                VStack(spacing: 4) {
                    Text("$\(listing.price, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(.black)
                    Text(listing.title)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
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
