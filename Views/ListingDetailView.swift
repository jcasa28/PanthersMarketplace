//
//  ListingDetailView.swift
//  Panthers Marketplace
//
//  Created by Cesar Calzadilla on 11/6/25.
//

import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var isFavorited = false

    var body: some View {
        ZStack(alignment: .bottom) {

            ScrollView {
                VStack(spacing: 0) {

                    Image(listing.imageName)
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
                            Label("MMC Campus", systemImage: "mappin.and.ellipse")
                            Circle().frame(width: 4, height: 4).foregroundStyle(.secondary)
                            Label("2h ago", systemImage: "clock")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        Text("Like New")
                            .font(.footnote)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // --- DESCRIPTION CARD ---
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Description").font(.headline)

                        Text("Barely used iPhone 15 Pro. Perfect condition. Includes charger and case. Great for all your FIU coursework!")
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
}

#Preview {
    NavigationStack {
        ListingDetailView(
            listing: Listing(title: "iPhone 15 Pro", price: 999.99, category: "Electronics", imageName: "iPhoneImageMock")
        )
    }
}
