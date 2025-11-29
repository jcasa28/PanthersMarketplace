//
//  ListingDetailView.swift
//  Panthers Marketplace
//
//  Created by Cesar Calzadilla on 11/6/25.
//

import SwiftUI

struct ListingDetailView: View {
    let listing: Post
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var isFavorited = false

    var body: some View {
        ZStack(alignment: .bottom) {

            ScrollView {
                VStack(spacing: 0) {

                    // Placeholder for image (Post model doesn't have image property yet)
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                                Text(listing.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(format: "$%.0f", listing.price))
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(listing.title)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        HStack(spacing: 12) {
                            Label("Seller: \(listing.sellerName)", systemImage: "person.circle")
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
                Button(action: {}) {
                    Text("Message Seller")
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
                .buttonStyle(.plain)
                .background(Color(.systemBackground))
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            
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
                        }
                    } label: {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
                createdAt: Date().addingTimeInterval(-7200) // 2 hours ago
            )
        )
    }
}
