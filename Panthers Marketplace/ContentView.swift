//
//  ContentView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var connectionStatus: String = "Testing connection..."
    @State private var users: [User] = []
    @State private var debugOutput: String = ""
    @State private var isConnected: Bool = false
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var chatVM = ChatViewModel()
    
    // Test stats without authentication
    @State private var testUser: User?
    @State private var testStats: UserStats?
    @State private var isLoadingTestStats = false
    @State private var testError: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(connectionStatus)
                        .padding()
                    
                    // Show navigation button only when connected
                    if isConnected {
                        NavigationLink(destination: FeedView()) {
                            HStack {
                                Image(systemName: "storefront")
                                    .foregroundColor(.white)
                                Text("Go to Panthers Marketplace")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding()
                            .background(Color(red:7/255, green:32/255, blue:64/255))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - User Stats Test Section (No Auth Required)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 User Stats Test (Select a user below)")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text("Tap any user below to view their stats")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            if isLoadingTestStats {
                                HStack {
                                    ProgressView()
                                    Text("Loading stats...")
                                }
                                .padding(.horizontal)
                            } else if let user = testUser, let stats = testStats {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Selected User: \(user.username)")
                                        .font(.subheadline)
                                        .bold()
                                    if let location = user.location {
                                        Text("Location: \(location)")
                                            .font(.caption)
                                    }
                                    Text("Role: \(user.role)")
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("User Statistics:")
                                        .font(.subheadline)
                                        .bold()
                                    
                                    HStack {
                                        Image(systemName: "list.bullet")
                                        Text("Listed Items: \(stats.listedItemsCount)")
                                    }
                                    
                                    HStack {
                                        Image(systemName: "heart")
                                        Text("Saved Items: \(stats.savedItemsCount)")
                                    }
                                    
                                    HStack {
                                        Image(systemName: "message")
                                        Text("Active Chats: \(stats.chatsCount)")
                                    }
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                        Text("Completed Transactions: \(stats.completedTransactions)")
                                    }
                                    
                                    HStack {
                                        Image(systemName: "dollarsign.circle")
                                        Text("Total Earnings: $\(String(format: "%.2f", stats.totalEarnings))")
                                    }
                                }
                                .font(.caption)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                // View Chats button
                                if let user = testUser {
                                    NavigationLink(destination: ChatListView().environmentObject(chatVM)) {
                                        HStack {
                                            Image(systemName: "message.fill")
                                                .foregroundColor(.white)
                                            Text("View \(user.username)'s Chats")
                                                .foregroundColor(.white)
                                                .font(.subheadline)
                                        }
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal)
                                }
                            } else if let error = testError {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            } else {
                                Text("No user selected yet")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    if !debugOutput.isEmpty {
                        Text("Debug Output:")
                            .font(.headline)
                        Text(debugOutput)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    
                    ForEach(users) { user in
                        Button(action: {
                            Task {
                                await loadStatsForUser(userId: user.id)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ID: \(user.id)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Username: \(user.username)")
                                    .font(.headline)
                                if let contact = user.contactInfo {
                                    Text("Contact: \(contact)")
                                }
                                if let location = user.location {
                                    Text("Location: \(location)")
                                }
                                Text("Role: \(user.role)")
                                Text("Created: \(user.createdAt)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("👆 Tap to view stats")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .italic()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(testUser?.id == user.id ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(testUser?.id == user.id ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Database Connection Test")
        }
        .task {
            do {
                let connectionResult = try await SupabaseService.shared.testConnection()
                isConnected = connectionResult
                connectionStatus = connectionResult ? "✅ Connected to Supabase!" : "❌ Connection failed"
                
                if connectionResult {
                    users = try await SupabaseService.shared.fetchUsers()
                }
            } catch {
                isConnected = false
                connectionStatus = "❌ Error: \(error.localizedDescription)"
                debugOutput = error.localizedDescription
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadStatsForUser(userId: String) async {
        isLoadingTestStats = true
        testError = nil
        
        do {
            let result = try await SupabaseService.shared.fetchUserStatsForTesting(userIdString: userId)
            testUser = result.user
            testStats = result.stats
            
            // Set the test user in ChatViewModel for messaging
            if let uuid = UUID(uuidString: userId) {
                chatVM.setTestUser(userId: uuid, username: result.user.username)
            }
            
            print("✅ Loaded stats for user: \(result.user.username)")
        } catch {
            testError = "Failed to load stats: \(error.localizedDescription)"
            print("❌ Error loading test stats: \(error)")
        }
        
        isLoadingTestStats = false
    }
}

#Preview {
    ContentView()
}
