//
//  ChatListView.swift
//  Panthers Marketplace
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var selectedThread: ThreadWithDetails?
    @State private var showNewConversation = false
    @StateObject private var searchVM = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if !chatVM.isAuthenticated {
                    // User not logged in
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Not Logged In")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Please log in to view and send messages")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else if chatVM.isLoadingThreads {
                    ProgressView("Loading conversations...")
                } else if chatVM.threads.isEmpty {
                    // No threads yet
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Conversations Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Start chatting with sellers about their posts!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // Thread list
                    List {
                        ForEach(chatVM.threads) { thread in
                            NavigationLink(destination: ChatDetailView(thread: thread, chatVM: chatVM)) {
                                ThreadRow(thread: thread)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                if let error = chatVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("💬 Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if chatVM.isAuthenticated {
                        Button(action: {
                            showNewConversation = true
                        }) {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if chatVM.isAuthenticated {
                        Button(action: {
                            Task {
                                await chatVM.loadThreads()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewConversation) {
                NewConversationSheet(chatVM: chatVM, searchVM: searchVM)
            }
            .onAppear {
                chatVM.startThreadPolling()
            }
            .onDisappear {
                chatVM.stopPolling()
            }
        }
    }
}

struct ThreadRow: View {
    let thread: ThreadWithDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(thread.otherPersonName)
                .font(.headline)
            
            Text(thread.postTitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            if let lastMessage = thread.lastMessagePreview {
                Text(lastMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChatDetailView: View {
    let thread: ThreadWithDetails
    @ObservedObject var chatVM: ChatViewModel
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatVM.currentThreadMessages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: chatVM.isMessageFromCurrentUser(message)
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: chatVM.currentThreadMessages.count) { oldValue, newValue in
                    scrollToBottom()
                }
            }
            
            // Message input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(chatVM.isSendingMessage)
                
                Button(action: sendMessage) {
                    if chatVM.isSendingMessage {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(messageText.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(20)
                    }
                }
                .disabled(messageText.isEmpty || chatVM.isSendingMessage)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .navigationTitle(thread.otherPersonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await chatVM.refreshCurrentThread()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            Task {
                await chatVM.loadMessages(for: thread)
            }
        }
        .onDisappear {
            chatVM.stopPolling()
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await chatVM.sendMessage(
                text: text,
                to: thread.otherPersonId,
                postId: thread.postId
            )
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = chatVM.currentThreadMessages.last else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(message.message)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - New Conversation Sheet
struct NewConversationSheet: View {
    @ObservedObject var chatVM: ChatViewModel
    @ObservedObject var searchVM: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPost: Post?
    
    var body: some View {
        NavigationView {
            VStack {
                if searchVM.isLoading {
                    ProgressView("Loading posts...")
                        .padding()
                } else if searchVM.searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Posts Available")
                            .font(.headline)
                        Text("Create a post first to start conversations")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(searchVM.searchResults) { post in
                        Button(action: {
                            selectedPost = post
                            startConversation(about: post)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(post.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("$\(String(format: "%.0f", post.price))")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                Text("Seller: \(post.sellerName ?? "Unknown")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .disabled(selectedPost == post)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Start New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startConversation(about post: Post) {
        Task {
            // Create thread with the current test user as buyer and post owner as seller
            await chatVM.startConversation(post: post)
            // Close the sheet
            dismiss()
        }
    }
}

#Preview {
    ChatListView()
}
