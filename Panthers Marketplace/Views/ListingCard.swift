//
//  ListingCard.swift
//  Panthers Marketplace
//
//  Created by John Borrego on 10/22/25.
//

import SwiftUI

struct Listing: Identifiable {
    let id = UUID()
    let title: String
    let price: Double
    let category: String
    let imageName: String
}

struct ListingCard: View {
    let listing: Listing

    var body: some View {
       
        
        VStack(alignment : .leading){
                VStack{
                    Image(listing.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width : 180,height : 168)
                        .clipped()
                        .aspectRatio(contentMode : .fill)
                        
                        
                }
                .offset(y : -38)
                
                VStack(alignment : .leading){
                    
                    Text("$\(listing.price , specifier : "%.2f")")
                    .foregroundColor(Color(red : 25/255, green : 40/255, blue : 60/255))
                    .padding(.bottom ,2)
                    .font(.system(size: 20))
                    
                   
                   
                    Text(listing.title)
                    .font(.system(size: 17))
                }
                .offset(y : -30)
                .padding(.leading)
                
            }
            .frame(width : 180,height : 280)
            .background(Color(.white))
        
            .cornerRadius(20)
            .shadow(radius : 2)
            .padding(.bottom)
           
          
            
        
        
       
        
    }
}

#Preview {
    
}
