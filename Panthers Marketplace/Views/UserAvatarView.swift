//
//  UserAvatarView.swift
//  Panthers Marketplace
//

import SwiftUI

struct UserAvatarView: View {
    let userIdString: String
    let size: CGFloat
    var cornerRadius: CGFloat = .infinity
    var placeholderSystemName: String = "person.fill"
    var reloadToken: Int = 0

    @State private var url: URL?
    @State private var isLoading = false
    @State private var loadTaskId = UUID()

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task { await loadURL() }
        .onChange(of: userIdString) { _, _ in Task { await loadURL() } }
        .onChange(of: reloadToken) { _, _ in Task { await loadURL() } }
        .accessibilityLabel("User avatar")
    }

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.15)
            Image(systemName: placeholderSystemName)
                .foregroundColor(.gray)
        }
    }

    @MainActor
    private func setURL(_ newURL: URL?) { url = newURL }

    private func loadURL() async {
        if isLoading { return }
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }

        let thisCallId = UUID()
        await MainActor.run { loadTaskId = thisCallId }

        let perUserSalt: String = {
            if let uuid = UUID(uuidString: userIdString) { return String(uuid.uuidString.prefix(8)) }
            return String(abs(userIdString.hashValue))
        }()

        // 1) Full HTTPS URL
        if userIdString.lowercased().hasPrefix("http") {
            if var comps = URLComponents(string: userIdString) {
                var queryItems = comps.queryItems ?? []
                queryItems.append(URLQueryItem(name: "_t", value: String(reloadToken)))
                queryItems.append(URLQueryItem(name: "_u", value: perUserSalt))
                comps.queryItems = queryItems
                let final = comps.url
                await MainActor.run { if loadTaskId == thisCallId { self.url = final } }
                return
            }
        }

        // Helper to append cache busters
        func withCacheBusters(_ url: URL) -> URL {
            guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            var items = comps.queryItems ?? []
            items.append(URLQueryItem(name: "_t", value: String(reloadToken)))
            items.append(URLQueryItem(name: "_u", value: perUserSalt))
            comps.queryItems = items
            return comps.url ?? url
        }

        // 2) Storage path branch (e.g., "users/<uuid>/profile-xxx.jpg")
        if userIdString.contains("/") && !userIdString.lowercased().hasPrefix("http") {
            do {
                if let signed = try await SupabaseService.shared.getSignedURL(path: userIdString, expiresInSeconds: 3600) {
                    let final = withCacheBusters(signed)
                    await MainActor.run { if loadTaskId == thisCallId { self.url = final } }
                    return
                } else {
                    // Signing was cancelled; attempt fallback below
                    // Try to infer UUID from the path and fetch by UUID
                    if let inferredUUID = userIdFromStoragePath(userIdString) {
                        if let fallback = try? await SupabaseService.shared.getUserAvatarURL(userId: inferredUUID, expiresInSeconds: 900),
                           let final = Optional(withCacheBusters(fallback)) {
                            await MainActor.run { if loadTaskId == thisCallId { self.url = final } }
                            return
                        }
                    }
                }
            } catch {
                // 404 or other error: try UUID fallback if possible
                if let inferredUUID = userIdFromStoragePath(userIdString),
                   let fallback = try? await SupabaseService.shared.getUserAvatarURL(userId: inferredUUID, expiresInSeconds: 900) {
                    let final = withCacheBusters(fallback)
                    await MainActor.run { if loadTaskId == thisCallId { self.url = final } }
                    return
                }
                print("❌ [UserAvatarView] Failed to sign storage path '\(userIdString)': \(error)")
            }
        }

        // 3) UUID branch (normal case)
        if let uuid = UUID(uuidString: userIdString) {
            if let signed = try? await SupabaseService.shared.getUserAvatarURL(userId: uuid, expiresInSeconds: 900) {
                let final = withCacheBusters(signed)
                await MainActor.run { if loadTaskId == thisCallId { self.url = final } }
                return
            } else {
                print("⚠️ [UserAvatarView] No avatar URL for user \(uuid)")
                await MainActor.run { if loadTaskId == thisCallId { self.url = nil } }
                return
            }
        }

        print("❌ [UserAvatarView] Unsupported identifier '\(userIdString)'; showing placeholder.")
        await MainActor.run { if loadTaskId == thisCallId { self.url = nil } }
    }

    // Extract UUID from "users/<uuid>/file.jpg"
    private func userIdFromStoragePath(_ path: String) -> UUID? {
        let parts = path.split(separator: "/")
        guard parts.count >= 2 else { return nil }
        return UUID(uuidString: String(parts[1]))
    }
}
