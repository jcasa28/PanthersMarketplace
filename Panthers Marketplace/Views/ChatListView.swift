//
//  ChatListView.swift
//  Panthers Marketplace
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var chat: ChatViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var selectedThread: ThreadWithDetails?
    @State private var showNewConversation = false
    @StateObject private var searchVM = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if !(chat.isAuthenticated) {
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
                } else if chat.isLoadingThreads {
                    ProgressView("Loading conversations...")
                } else if chat.threads.isEmpty {
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
                    List {
                        ForEach(chat.threads) { thread in
                            NavigationLink(
                                destination: ChatDetailView(thread: thread, observedChatVM: chat)
                                    .environmentObject(profileVM)
                            ) {
                                ThreadRow(
                                    otherPersonId: thread.otherPersonId,
                                    otherPersonName: thread.otherPersonName,
                                    postTitle: thread.postTitle,
                                    lastMessagePreview: thread.lastMessagePreview,
                                    avatarUpdatedAt: thread.otherPersonAvatarUpdatedAt,
                                    otherPersonAvatarPath: thread.otherPersonAvatarPath
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                if let error = chat.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("💬 Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if chat.isAuthenticated {
                        Button {
                            showNewConversation = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if chat.isAuthenticated {
                        Button {
                            Task { await chat.loadThreads() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Refresh conversations")
                    }
                }
            }
            .sheet(isPresented: $showNewConversation) {
                NewConversationSheet(chatVM: chat, searchVM: searchVM)
                    .environmentObject(profileVM)
            }
            .onAppear {
                Task { await chat.loadThreads() }
            }
            .onDisappear {
                chat.stopPolling()
            }
        }
    }
}

struct ThreadRow: View {
    let otherPersonId: UUID
    let otherPersonName: String
    let postTitle: String
    let lastMessagePreview: String?
    let avatarUpdatedAt: Date?
    let otherPersonAvatarPath: String?
    
    private var reloadToken: Int {
        if let ts = avatarUpdatedAt {
            return Int(ts.timeIntervalSince1970)
        } else {
            return 0
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let path = otherPersonAvatarPath, !path.isEmpty {
                // We have a storage path, let the view sign it directly
                UserAvatarView(
                    userIdString: path,
                    size: 44,
                    reloadToken: reloadToken
                )
            } else {
                // Fallback to fetching by user UUID
                UserAvatarView(
                    userIdString: otherPersonId.uuidString,
                    size: 44,
                    reloadToken: reloadToken
                )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(otherPersonName)
                    .font(.headline)
                
                Text(postTitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                if let last = lastMessagePreview {
                    Text(last)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct ChatDetailView: View {
    let thread: ThreadWithDetails
    @ObservedObject var observedChatVM: ChatViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        content
            .navigationTitle(thread.otherPersonName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        if let path = thread.otherPersonAvatarPath, !path.isEmpty {
                            UserAvatarView(
                                userIdString: path,
                                size: 28,
                                reloadToken: Int(thread.otherPersonAvatarUpdatedAt?.timeIntervalSince1970 ?? 0)
                            )
                        } else {
                            UserAvatarView(
                                userIdString: thread.otherPersonId.uuidString,
                                size: 28,
                                reloadToken: Int(thread.otherPersonAvatarUpdatedAt?.timeIntervalSince1970 ?? 0)
                            )
                        }
                        Text(thread.otherPersonName)
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await observedChatVM.refreshCurrentThread() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh messages")
                }
            }
            .onAppear {
                Task { await observedChatVM.loadMessages(for: thread) }
            }
            .onDisappear {
                observedChatVM.stopPolling()
            }
    }
    
    private var content: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(observedChatVM.currentThreadMessages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: observedChatVM.isMessageFromCurrentUser(message)
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
                .onChange(of: observedChatVM.currentThreadMessages.count) { _, _ in
                    scrollToBottom()
                }
            }
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(observedChatVM.isSendingMessage)
                
                Button(action: sendMessage) {
                    if observedChatVM.isSendingMessage {
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
                .disabled(messageText.isEmpty || observedChatVM.isSendingMessage)
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageText = ""
        Task {
            await observedChatVM.sendMessage(
                text: text,
                to: thread.otherPersonId,
                postId: thread.postId
            )
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = observedChatVM.currentThreadMessages.last else { return }
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

struct NewConversationSheet: View {
    @ObservedObject var chatVM: ChatViewModel
    @ObservedObject var searchVM: SearchViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
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
                        Button {
                            selectedPost = post
                            startConversation(about: post)
                        } label: {
                            HStack(spacing: 12) {
                                UserAvatarView(
                                    userIdString: post.userId.uuidString,
                                    size: 28,
                                    reloadToken: chatVM.chatAvatarReloadToken // list of posts can keep using chat token
                                )
                                VStack(alignment: .leading, spacing: 6) {
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
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func startConversation(about post: Post) {
        Task {
            await chatVM.startConversation(post: post)
            dismiss()
        }
    }
}

#Preview {
    ChatListView()
        .environmentObject(ProfileViewModel())
        .environmentObject(ChatViewModel())
}

