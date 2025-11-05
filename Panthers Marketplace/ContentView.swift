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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(connectionStatus)
                    .padding()
                
                if !debugOutput.isEmpty {
                    Text("Debug Output:")
                        .font(.headline)
                    Text(debugOutput)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                
                ForEach(users) { user in
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
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
        .task {
            do {
                let isConnected = try await SupabaseService.shared.testConnection()
                connectionStatus = isConnected ? "Connected to Supabase!" : "Connection failed"
                
                if isConnected {
                    users = try await SupabaseService.shared.fetchUsers()
                }
            } catch {
                connectionStatus = "Error: \(error.localizedDescription)"
                debugOutput = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
}
