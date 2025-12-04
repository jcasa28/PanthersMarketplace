//
//  ChatViewModel.swift
//  Panthers Marketplace
//

import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var threads: [ThreadWithDetails] = []
    @Published var currentThreadMessages: [Message] = []
    @Published var isLoadingThreads = false
    @Published var isLoadingMessages = false
    @Published var isSendingMessage = false
    @Published var errorMessage: String?
    
    // MARK: - Authentication
    private var authVM: AuthViewModel?
    private var currentUserId: UUID? { authVM?.userId }
    var isAuthenticated: Bool { authVM?.isLoggedIn ?? false }
    
    // MARK: - Current Thread
    @Published var currentThread: ThreadWithDetails?
    
    // MARK: - Avatar reload for chat lists
    @Published var chatAvatarReloadToken: Int = 0
    
    // MARK: - Polling (optional)
    private var messagePollingTimer: Timer?
    private var threadPollingTimer: Timer?
    private let pollingInterval: TimeInterval = 3.0
    
    // MARK: - Init
    init(authVM: AuthViewModel? = nil) {
        self.authVM = authVM
        print("💬 ChatViewModel initialized")
    }
    
    // MARK: - Threads
    func loadThreads() async {
        guard isAuthenticated, let userId = currentUserId else {
            errorMessage = "Please log in to view chats."
            threads = []
            return
        }
        if isLoadingThreads { return }
        isLoadingThreads = true
        errorMessage = nil
        
        do {
            let fetched = try await SupabaseService.shared.fetchThreadsForUser(userId: userId)
            threads = fetched
            // Bump token so avatars in list refresh
            chatAvatarReloadToken &+= 1
            print("✅ Loaded \(threads.count) threads for user \(userId)")
        } catch {
            errorMessage = "Failed to load threads: \(error.localizedDescription)"
            print("❌ Error loading threads: \(error)")
            threads = []
        }
        
        isLoadingThreads = false
    }
    
    func refreshThreads() async {
        await loadThreads()
    }
    
    func refreshCurrentThread() async {
        guard let thread = currentThread else { return }
        await loadMessages(for: thread)
    }
    
    func isMessageFromCurrentUser(_ message: Message) -> Bool {
        message.senderId == currentUserId
    }
    
    // MARK: - Messages
    func loadMessages(for thread: ThreadWithDetails) async {
        currentThread = thread
        isLoadingMessages = true
        errorMessage = nil
        
        do {
            let messages = try await SupabaseService.shared.fetchMessages(threadId: thread.id)
            currentThreadMessages = messages
            print("✅ Loaded \(messages.count) messages for thread \(thread.id)")
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            print("❌ Error loading messages: \(error)")
            currentThreadMessages = []
        }
        
        isLoadingMessages = false
    }
    
    func sendMessage(text: String, to receiverId: UUID, postId: UUID) async {
        guard let senderId = currentUserId else {
            errorMessage = "Please log in to send messages."
            print("⚠️ Cannot send message: User not authenticated")
            return
        }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let thread = currentThread else {
            errorMessage = "No active thread."
            print("⚠️ Cannot send message: currentThread is nil")
            return
        }
        
        isSendingMessage = true
        errorMessage = nil
        
        do {
            let newMessage = try await SupabaseService.shared.sendMessage(
                senderId: senderId,
                receiverId: receiverId,
                postId: postId,
                threadId: thread.id,
                messageText: text
            )
            currentThreadMessages.append(newMessage)
            print("✅ Message sent and appended locally")
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            print("❌ Error sending message: \(error)")
        }
        
        isSendingMessage = false
    }
    
    // MARK: - Start Conversation
    func createThread(postId: UUID, buyerId: UUID, sellerId: UUID) async throws -> UUID {
        try await SupabaseService.shared.createThread(postId: postId, buyerId: buyerId, sellerId: sellerId)
    }
    
    func startConversation(post: Post) async {
        guard let buyerId = currentUserId else {
            errorMessage = "Please log in to start a conversation."
            print("⚠️ Cannot create thread: User not authenticated")
            return
        }
        
        do {
            let threadId = try await createThread(postId: post.id, buyerId: buyerId, sellerId: post.userId)
            await loadThreads()
            if let thread = threads.first(where: { $0.id == threadId }) {
                await loadMessages(for: thread)
            } else {
                let thread = ThreadWithDetails(
                    id: threadId,
                    postId: post.id,
                    postTitle: post.title,
                    buyerId: buyerId,
                    sellerId: post.userId,
                    otherPersonName: post.sellerName ?? "Seller",
                    otherPersonId: post.userId,
                    createdAt: Date()
                )
                await loadMessages(for: thread)
            }
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            print("❌ Error creating thread: \(error)")
        }
    }
    
    // MARK: - Polling controls (optional)
    func stopPolling() {
        messagePollingTimer?.invalidate()
        messagePollingTimer = nil
        threadPollingTimer?.invalidate()
        threadPollingTimer = nil
    }
}
