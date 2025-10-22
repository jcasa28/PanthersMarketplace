//
//  FeedView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//


import SwiftUI


struct FeedView: View {
    
     var columns = [
        GridItem(.flexible(), spacing:15),
        GridItem(.flexible(),spacing:15),
        GridItem(.flexible(),spacing:15)
    ]

    var body: some View {
        NavigationStack{
            VStack(alignment : .leading){
                
                    
                    
                VStack{
                    
                    HStack{
                        
                        VStack(alignment : .leading){
                            Text("FIU Marketplace")
                                .font(.title)
                                .foregroundStyle(Color(.white))
                            Text("Panthers Buy & Sell")
                                .foregroundStyle(Color(red:146/255,green:175/255,blue:201/255))
                            
                            
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person")
                                .foregroundStyle(Color.white)
                                .font(.system(size: 25))
                        }
                        
                    }
                    .padding()
                       
                    
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search for items...", text: .constant(""))
                            .textFieldStyle(PlainTextFieldStyle())
                            
                            
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    
                    
                }
                .background(Color(red:7/255,green:32/255,blue:64/255))
                .padding(.top,8)
                
            
                
                Text("Categories")
                    .padding(.leading)
                    .font(.title)
                    .fontWeight(.bold)
                
                
                LazyVGrid(columns : columns){
                    CategoryCard(label: "Electronics", icon: "📱", red:219, green : 234,blue : 254)
                       
                    
                    CategoryCard(label: "Books", icon: "📚", red: 221, green:252,blue:230 )
                       
                    
                    CategoryCard(label: "Furniture", icon: "🛋️",red:243,green:232,blue:255 )
                    
                    CategoryCard(label : "Clothing",icon: "👕",red:254,green:231,blue:244)
                    
                    CategoryCard(label : "Transportation",icon: "🚲",red:255,green:237,blue:212)
                    
                    CategoryCard(label : "Other",icon: "📦",red:244,green:245,blue:247)
                    
                    

                    
                   
                    
                }
                .padding(.horizontal)
                
                Text("Recent Listings")
                    .font(Font.system(size: 22))
                    .padding(.leading)
                
                
                let iphoneListing = Listing(
                    title: "iPhone 15 Pro",
                    price: 999.99,
                    category: "Electronics",
                    imageName: "iphoneImageMock"
                )

               ScrollView(.horizontal, showsIndicators: false){
                   HStack{
                       ListingCard(listing : iphoneListing)
                       Spacer()
                       ListingCard(listing : iphoneListing)
                       Spacer()
                       ListingCard(listing : iphoneListing)
                   }
                  
                }
               .padding(.horizontal)
               
                
               
                
            }
            .safeAreaInset(edge : .bottom){
                
                
                
                
                
                ZStack{
                    
                    HStack{
                        Spacer()
                        VStack{
                            Image(systemName : "magnifyingglass")
                            Text("Browse")
                        }
                        Spacer()
                        VStack{
                            Image(systemName : "heart")
                            Text("Saved")
                            
                        }
                        Spacer()
                        ZStack {
                                    Circle()
                                        .fill(Color(red:7/255,green:32/255,blue:64/255))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .font(.system(size: 25))
                                }
                            
                        Spacer()
                        VStack{
                            Image(systemName : "ellipsis.message")
                            Text("Messages")
                        }
                        Spacer()
                        
                        NavigationLink(destination : ProfileView()){
                            VStack{
                                Image(systemName : "person" )
                                Text("Profile")
                            }
                        }
                        Spacer()
                    }
                    .background(Color.white)
                    .frame(height : 70)
                    .foregroundStyle(Color(red : 136/255,green : 135/255, blue : 138/255))
                    
                }
            }
            
             
            
            
            
                
        }
        
    }
    
}
#Preview{
    FeedView()
}

