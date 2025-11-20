//
//  ProfileView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import SwiftUI

struct ProfileView: View {
    private let headerColor = Color(red: 9/255, green: 27/255, blue: 61/255)
    
    @StateObject private var searchVM = SearchViewModel()
    
    
    enum ProfileTab: String, CaseIterable, Identifiable {
        case myListings = "My Listings"
        case savedItems = "Saved Items"
        
        var id: String { rawValue }
    }
    
    @State private var selectedTab: ProfileTab
    
    init(initialSelectedTab: ProfileTab = .myListings) {
        _selectedTab = State(initialValue: initialSelectedTab)
    }

    private var myListings: [Post] {
        searchVM.searchResults
    }
    
    private var savedListings: [Post] {
        searchVM.searchResults
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        profileHeader
                        statsRow
                        tabPicker
                        listingsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    private var profileHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(headerColor)
            
            HStack(alignment: .center, spacing: 16) {
                Image("profile_avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("John Doe")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text("MMC Campus")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.subheadline)
                        Text("4.8")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Text("(24 reviews)")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                
                Spacer()
                
                Button(action: {
                
                }) {
                    Text("Edit Profile")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(headerColor)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(count: 12, label: "Listed")
            Divider().frame(height: 32)
            statItem(count: 8, label: "Saved")
            Divider().frame(height: 32)
            statItem(count: 5, label: "Chats")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
    }
    
    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ProfileTab.allCases) { tab in
                Text(tab.rawValue)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 4)
    }
    
    private var listingsSection: some View {
        let data = selectedTab == .myListings ? myListings : savedListings
        
        return VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(data) { post in
                    NavigationLink(destination: ListingDetailView(listing: post)) {
                        ListingCard(listing: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 4)
    }
}

