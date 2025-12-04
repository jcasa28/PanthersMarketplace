//
//  ProfileView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import SwiftUI

struct ProfileView: View {
    private let headerColor = Color(red: 9/255, green: 27/255, blue: 61/255)

    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel
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
        profileVM.listedItems
    }
    
    private var savedListings: [Post] {
        profileVM.savedItems
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                await authVM.signOut()
                            }
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .regular))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            Task {
                await profileVM.refreshProfile()
            }
        }
    }
    
    // MARK: - Header
    
    private var profileHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(headerColor)
            
            HStack(alignment: .center, spacing: 16) {
                // 1) Local preview if user just picked an image in this session
                if let img = profileVM.profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                // 2) Signed URL from storage (preferred for persisted avatars)
                else if let url = profileVM.avatarURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderAvatar
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholderAvatar
                        @unknown default:
                            placeholderAvatar
                        }
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                // 3) Per-user loader (will refresh when reloadToken changes)
                else if let id = profileVM.user?.id {
                    UserAvatarView(userIdString: id, size: 70, reloadToken: profileVM.avatarReloadToken)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                // 4) Final fallback
                else {
                    placeholderAvatar
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    if let user = profileVM.user {
                        Text(user.username)
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            if let location = user.location, !location.isEmpty {
                                Text(location)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.subheadline)

                        Text(String(format: "%.1f", profileVM.averageRating))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)

                        Text("(\(profileVM.ratings.count) reviews)")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }

                Spacer()

                NavigationLink {
                    EditProfileView()
                        .environmentObject(profileVM)
                } label: {
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
    
    private var placeholderAvatar: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.3))
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
                .padding(15)
        }
    }

    // MARK: - Stats
    
    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(count: profileVM.stats.listedItemsCount, label: "Listed")
            Divider().frame(height: 32)
            statItem(count: profileVM.stats.savedItemsCount, label: "Saved")
            Divider().frame(height: 32)

            NavigationLink(destination: ChatListView()) {
                statItem(count: profileVM.stats.chatsCount, label: "Chats")
                    .foregroundColor(.primary)
            }
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

    // MARK: - Tabs
    
    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ProfileTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 4)
    }

    // MARK: - Listings
    
    private var listingsSection: some View {
        let isSavedTab = selectedTab == .savedItems
        let data = isSavedTab ? savedListings : myListings

        return VStack(alignment: .leading, spacing: 12) {
            if isSavedTab {
                Text("Saved Items")
                    .font(.title2.weight(.semibold))
                    .padding(.bottom, 4)

                if profileVM.isLoadingSaved {
                    ProgressView("Loading saved posts...")
                        .padding(.vertical, 16)
                } else if data.isEmpty {
                    Text("No saved posts found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(data) { post in
                    NavigationLink(
                        destination:
                            ListingDetailView(listing: post)
                                .environmentObject(profileVM)
                    ) {
                        ListingCard(listing: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel())
        .environmentObject(AuthViewModel())
}
