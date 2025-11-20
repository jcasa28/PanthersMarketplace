//
//  FeedView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var searchVM = SearchViewModel()
    @State private var showUploadPost = false
    @State private var selectedCategory: ProductCategory?
    @State private var selectedCampus: Campus?
    @State private var showingFilterSheet = false
    @State private var minPrice: String = ""
    @State private var maxPrice: String = ""

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

                        // Search bar with filter button
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search for items...", text: $searchVM.searchQuery)
                                .textFieldStyle(PlainTextFieldStyle())
                            if searchVM.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.8)
                            } else if !searchVM.searchQuery.isEmpty {
                                Button(action: { searchVM.clearSearch() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            Button(action: { showingFilterSheet = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.gray)
                            }
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

                            if searchVM.searchQuery.isEmpty && selectedCategory == nil {
                                // Show categories only when not searching
                                Text("Categories")
                                    .font(.title2)
                                    .bold()
                                    .padding(.leading)

                                LazyVGrid(columns: columns, spacing: 15) {
                                    CategoryCard(label: "Electronics", icon: "📱", red: 219, green: 234, blue: 254)
                                        .onTapGesture {
                                            selectedCategory = .electronics
                                            searchVM.filterByCategory(.electronics)
                                        }
                                    CategoryCard(label: "Books", icon: "📚", red: 221, green: 252, blue: 230)
                                        .onTapGesture {
                                            selectedCategory = .books
                                            searchVM.filterByCategory(.books)
                                        }
                                    CategoryCard(label: "Furniture", icon: "🛋️", red: 243, green: 232, blue: 255)
                                        .onTapGesture {
                                            selectedCategory = .furniture
                                            searchVM.filterByCategory(.furniture)
                                        }
                                    CategoryCard(label: "Clothing", icon: "👕", red: 254, green: 231, blue: 244)
                                        .onTapGesture {
                                            selectedCategory = .clothing
                                            searchVM.filterByCategory(.clothing)
                                        }
                                    CategoryCard(label: "Transportation", icon: "🚲", red: 255, green: 237, blue: 212)
                                        .onTapGesture {
                                            selectedCategory = .transportation
                                            searchVM.filterByCategory(.transportation)
                                        }
                                    CategoryCard(label: "Other", icon: "📦", red: 244, green: 245, blue: 247)
                                        .onTapGesture {
                                            selectedCategory = .other
                                            searchVM.filterByCategory(.other)
                                        }
                                }
                                .padding(.horizontal)
                            }

                            // Active filters display
                            if searchVM.getCurrentFilters().hasActiveFilters() {
                                let filters = searchVM.getCurrentFilters()
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        if let category = filters.category {
                                            FilterTag(text: category.rawValue) {
                                                selectedCategory = nil
                                                searchVM.filterByCategory(nil)
                                            }
                                        }
                                        if let campus = filters.campus {
                                            FilterTag(text: campus.rawValue) {
                                                selectedCampus = nil
                                                searchVM.filterByCampus(nil)
                                            }
                                        }
                                        if let minPrice = filters.minPrice, let maxPrice = filters.maxPrice {
                                            FilterTag(text: "$\(String(format: "%.2f", minPrice))-$\(String(format: "%.2f", maxPrice))") {
                                                self.minPrice = ""
                                                self.maxPrice = ""
                                                searchVM.filterByPrice(min: nil, max: nil)
                                            }
                                        }
                                        if filters.hasActiveFilters() {
                                            Button(action: {
                                                selectedCategory = nil
                                                selectedCampus = nil
                                                self.minPrice = ""
                                                self.maxPrice = ""
                                                searchVM.clearFilters()
                                            }) {
                                                Text("Clear All")
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Search results or recent listings
                            Text(searchVM.searchQuery.isEmpty ? "Recent Listings" : "Search Results")
                                .font(.title2)
                                .bold()
                                .padding(.leading)

                            if let error = searchVM.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                LazyVGrid(columns: listingColumns, spacing: 20) {
                                    ForEach(searchVM.searchResults) { post in
                                        NavigationLink(destination: ListingDetailView(listing: post)) {
                                            ListingCard(listing: post)
                                        }
                                        .buttonStyle(.plain)
                                        .onAppear {
                                            // Trigger load more when user scrolls near the end
                                            searchVM.loadMoreIfNeeded(currentPost: post)
                                        }
                                    }
                                    
                                    // Loading indicator for pagination
                                    if searchVM.isLoadingMore {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                            Spacer()
                                        }
                                        .gridCellColumns(2)
                                        .padding()
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                                .frame(height: 100)
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
                    NavigationLink(destination: ProfileView(initialSelectedTab: .savedItems)) {
                        VStack {
                            Image(systemName: "bookmark")
                            Text("Saved")
                        }
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
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    selectedCategory: $selectedCategory,
                    selectedCampus: $selectedCampus,
                    minPrice: $minPrice,
                    maxPrice: $maxPrice,
                    onApply: { category, campus, min, max in
                        searchVM.filterByCategory(category)
                        searchVM.filterByCampus(campus)
                        if let minVal = Double(min), let maxVal = Double(max) {
                            searchVM.filterByPrice(min: minVal, max: maxVal)
                        }
                        showingFilterSheet = false
                    }
                )
            }
        }
    }
}

// MARK: - Filter Tag View
struct FilterTag: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(text)
                .padding(.leading, 8)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter Sheet View
struct FilterSheetView: View {
    @Binding var selectedCategory: ProductCategory?
    @Binding var selectedCampus: Campus?
    @Binding var minPrice: String
    @Binding var maxPrice: String
    let onApply: (ProductCategory?, Campus?, String, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as ProductCategory?)
                        ForEach(ProductCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as ProductCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Campus Location")) {
                    Picker("Campus", selection: $selectedCampus) {
                        Text("All Campuses").tag(nil as Campus?)
                        Text("MMC Campus").tag(Campus.mmc as Campus?)
                        Text("BBC Campus").tag(Campus.bbc as Campus?)
                        Text("Engineering Campus").tag(Campus.engineering as Campus?)
                        Text("Business Campus").tag(Campus.business as Campus?)
                        Text("Housing").tag(Campus.housing as Campus?)
                        Text("Library").tag(Campus.library as Campus?)
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Price Range")) {
                    HStack {
                        TextField("Min", text: $minPrice)
                            .keyboardType(.decimalPad)
                        Text("-")
                        TextField("Max", text: $maxPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section {
                    Button("Apply Filters") {
                        onApply(selectedCategory, selectedCampus, minPrice, maxPrice)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FeedView()
}

