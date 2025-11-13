//
//  ChatListView.swift
//  Panthers Marketplace
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var chatVM = ChatViewModel()
    @State private var selectedThread: ThreadWithDetails?
    
    var body: some View {
        NavigationView {
            VStack {
                if chatVM.testUserId == nil {
                    // No test user selected
                    VStack(spacing: 20) {
                        Image(systemName: "message.badge.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No User Selected")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Go to ContentView and select a user to view their chats")
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    if chatVM.testUserId != nil {
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
                .onChange(of: chatVM.currentThreadMessages.count) { _ in
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

#Preview {
    ChatListView()
}
