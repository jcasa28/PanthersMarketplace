//
//  FeedView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import SwiftUI

struct FeedView: View {
    @State private var showUploadPost = false

    // Category grid (3 across)
    var columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    // Listings grid (2 across)
    var listingColumns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    @State private var listings: [Listing] = [
        Listing(title: "iPhone 15 Pro", price: 999.99, category: "Electronics", imageName: "iphoneImageMock"),
        Listing(title: "iPhone 15 Pro", price: 999.99, category: "Electronics", imageName: "iphoneImageMock"),
        Listing(title: "iPhone 15 Pro", price: 999.99, category: "Electronics", imageName: "iphoneImageMock")
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                VStack(spacing: 0) {
                    // Top header + search
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("FIU Marketplace")
                                    .font(.title)
                                    .foregroundColor(.white)
                                Text("Panthers Buy & Sell")
                                    .foregroundColor(Color(red:146/255, green:175/255, blue:201/255))
                            }
                            Spacer()
                            NavigationLink(destination: ProfileView()) {
                                Image(systemName: "person")
                                    .foregroundColor(.white)
                                    .font(.system(size: 25))
                            }
                        }
                        .padding(.horizontal)

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
                    .background(Color(red:7/255, green:32/255, blue:64/255))

                    // Scrollable content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {

                            Text("Categories")
                                .font(.title2)
                                .bold()
                                .padding(.leading)

                            LazyVGrid(columns: columns, spacing: 15) {
                                CategoryCard(label: "Electronics",   icon: "📱", red:219, green:234, blue:254)
                                CategoryCard(label: "Books",         icon: "📚", red:221, green:252, blue:230)
                                CategoryCard(label: "Furniture",     icon: "🛋️", red:243, green:232, blue:255)
                                CategoryCard(label: "Clothing",      icon: "👕", red:254, green:231, blue:244)
                                CategoryCard(label: "Transportation",icon: "🚲", red:255, green:237, blue:212)
                                CategoryCard(label: "Other",         icon: "📦", red:244, green:245, blue:247)
                            }
                            .padding(.horizontal)

                            Text("Recent Listings")
                                .font(.title2)
                                .padding(.leading)

                            // Each card pushes ListingDetailView
                            LazyVGrid(columns: listingColumns, spacing: 10) {
                                ForEach(listings) { item in
                                    NavigationLink(destination: ListingDetailView(listing: item)) {
                                        ListingCard(listing: item)
                                    }
                                    .buttonStyle(.plain) // keep card look
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                        .padding(.top)
                    }
                }

                // Bottom bar
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "magnifyingglass")
                        Text("Browse")
                    }
                    Spacer()
                    VStack {
                        Image(systemName: "heart")
                        Text("Saved")
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color(red:7/255, green:32/255, blue:64/255))
                            .frame(width: 50, height: 50)
                        Button {
                            showUploadPost = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 25))
                        }
                    }
                    Spacer()
                    VStack {
                        Image(systemName: "ellipsis.message")
                        Text("Messages")
                    }
                    Spacer()
                    NavigationLink(destination: ProfileView()) {
                        VStack {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                    }
                    Spacer()
                }
                .frame(height: 70)
                .padding(.top, 4)
                .foregroundColor(Color(red:136/255, green:135/255, blue:138/255))
                .background(
                    Color.white
                        .shadow(radius: 0.2)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $showUploadPost) {
                UploadPostView()
            }
        }

    }
}

#Preview {
    FeedView()
}
