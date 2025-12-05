//
//  ListingDetailView.swift
//  Panthers Marketplace
//

import SwiftUI

struct ListingDetailView: View {
    let listing: Post
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var chatVM: ChatViewModel

    @State private var isFavorited = false
    
    @State private var showEditSheet = false
    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editPriceText = ""
    @State private var editCategory = ""
    @State private var editLocation = ""
    @State private var isUpdating = false
    @State private var updateError: String?
    
  
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
   
    @State private var isStartingChat = false
    @State private var navigateToChat = false
    @State private var chatErrorMessage: String?
    @State private var showChatError = false
    // ============================================================

    var body: some View {
        ZStack(alignment: .bottom) {

            ScrollView {
                VStack(spacing: 0) {

                    // Placeholder for image (Post model doesn't have image property yet)
                    Image(listing.categoryImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipped()

                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(format: "$%.0f", listing.price))
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(listing.title)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        HStack(spacing: 12) {
                            // Seller avatar + name
                            UserAvatarView(
                                userIdString: listing.userId.uuidString,
                                size: 20,
                                cornerRadius: 10,
                                reloadToken: profileVM.avatarReloadToken
                            )
                            if let sellerName = listing.sellerName {
                                Text("Seller: \(sellerName)")
                            } else {
                                Text("Seller: Unknown")
                            }
                            Circle().frame(width: 4, height: 4).foregroundStyle(.secondary)
                            Label(timeAgoString(from: listing.createdAt), systemImage: "clock")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        Text(listing.status.capitalized)
                            .font(.footnote)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor(for: listing.status).opacity(0.12))
                            .foregroundStyle(statusColor(for: listing.status))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // --- DESCRIPTION CARD ---
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Description").font(.headline)

                        Text(listing.description)
                            .font(.body)
                            .foregroundStyle(.primary)

                        Divider()

                        Text("Category").font(.headline)
                        Text(listing.category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            // --- BOTTOM ACTION BAR ---
            VStack(spacing: 0) {
                Divider().background(Color.black.opacity(0.1))

                // 🆕 Message Seller button wired to ChatViewModel
                Button {
                    Task { await handleMessageSellerTap() }
                } label: {
                    Text(isStartingChat ? "Starting chat..." : "Message Seller")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 20/255, green: 40/255, blue: 80/255))
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                .disabled(isStartingChat)
                .buttonStyle(.plain)
                .background(Color(.systemBackground))
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
           
            ToolbarItem(placement: .topBarLeading) {
                if listing.userId == authVM.userId {
                    Menu {
                        // Edit option
                        Button {
                            editTitle = listing.title
                            editDescription = listing.description
                            editPriceText = String(format: "%.2f", listing.price)
                            editCategory = listing.category
                            editLocation = ""
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        // Delete option (destructive style)
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    ShareLink(
                        item: "\(listing.title) — $\(Int(listing.price))",
                        message: Text("Check this out on Panthers Marketplace!")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            isFavorited.toggle()
                            // Save or unsave the post to/from Supabase
                            Task {
                                do {
                                    if isFavorited {
                                        // Save post to saved_items
                                        try await SupabaseService.shared.savePost(userId: authVM.userId ?? UUID(), postId: listing.id)
                                    } else {
                                        // Remove post from saved_items
                                        try await SupabaseService.shared.unsavePost(userId: authVM.userId ?? UUID(), postId: listing.id)
                                    }
                                } catch {
                                    print("❌ Error saving/unsaving post: \(error)")
                                    // Toggle back on error
                                    isFavorited.toggle()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isFavorited ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Edit Listing")) {
                        TextField("Title", text: $editTitle)
                        TextField("Price", text: $editPriceText)
                            .keyboardType(.decimalPad)
                        TextField("Category", text: $editCategory)
                        TextField("Location", text: $editLocation)
                    }
                    
                    Section(header: Text("Description")) {
                        TextEditor(text: $editDescription)
                            .frame(minHeight: 100)
                    }
                    
                    if let error = updateError {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Edit Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showEditSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await saveChanges()
                            }
                        }
                        .disabled(isUpdating)
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete this listing?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await performDelete()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This listing will be removed from the marketplace. This action cannot be undone.")
        }
        // 🆕 navigate straight into ChatDetailView when thread is ready
        .navigationDestination(isPresented: $navigateToChat) {
            if let thread = chatVM.currentThread {
                ChatDetailView(thread: thread, observedChatVM: chatVM)
                    .environmentObject(profileVM)
            } else {
                ChatListView()
                    .environmentObject(chatVM)
                    .environmentObject(profileVM)
            }
        }
        // 🆕 simple error alert for chat problems
        .alert("Chat Error", isPresented: $showChatError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(chatErrorMessage ?? "Something went wrong starting the chat.")
        }
    }
    
    // MARK: - CHAT HANDLER
    
    @MainActor
    private func handleMessageSellerTap() async {
        // 1. Require login
        guard authVM.isLoggedIn else {
            chatErrorMessage = "Please log in to message the seller."
            showChatError = true
            return
        }

        isStartingChat = true
        defer { isStartingChat = false }

        // 2. Use ChatViewModel to create / find thread for this listing
        await chatVM.startConversation(post: listing)

        // 3. If we have a current thread, navigate into ChatDetailView
        if chatVM.currentThread != nil {
            navigateToChat = true
        } else {
            chatErrorMessage = chatVM.errorMessage ?? "Could not start conversation."
            showChatError = true
        }
    }
    
    // MARK: - EXISTING HELPERS (unchanged)
    
    @MainActor
    private func saveChanges() async { /* your existing implementation */ }
    
    @MainActor
    private func performDelete() async {
        guard !isDeleting else { return }
        isDeleting = true
        updateError = nil

        do {
            // Use ListingsViewModel to delete from Supabase
            let listingsVM = ListingsViewModel(authVM: authVM)
            try await listingsVM.deleteListing(postId: listing.id)

            print("✅ Listing deleted in Supabase, dismissing detail view")
            dismiss()   // go back to previous screen (Feed/Profile)
        } catch {
            print("❌ Failed to delete listing: \(error)")
            updateError = "Failed to delete: \(error.localizedDescription)"
            isDeleting = false
        }
    }

    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "sold":
            return .red
        case "pending":
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        ListingDetailView(
            listing: Post(
                id: UUID(),
                title: "iPhone 15 Pro",
                description: "Barely used iPhone 15 Pro. Perfect condition. Includes charger and case. Great for all your FIU coursework!",
                price: 999.99,
                category: "Electronics",
                userId: UUID(),
                sellerName: "johndoe",
                status: "active",
                createdAt: Date().addingTimeInterval(-7200)
            )
        )
        .environmentObject(AuthViewModel())
        .environmentObject(ProfileViewModel())
        .environmentObject(ChatViewModel())     
    }
}
