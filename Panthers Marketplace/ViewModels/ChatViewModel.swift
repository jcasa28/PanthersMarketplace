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
    
    // MARK: - Authentication (like posts use)
    private var authVM: AuthViewModel?
    
    // MARK: - Current Thread
    @Published var currentThread: ThreadWithDetails?
    
    // MARK: - Real-time polling (simplified real-time updates)
    private var messagePollingTimer: Timer?
    private var threadPollingTimer: Timer?
    private let pollingInterval: TimeInterval = 3.0 // Poll every 3 seconds
    
    // MARK: - Initialization
    init(authVM: AuthViewModel? = nil) {
        self.authVM = authVM
        print("💬 ChatViewModel initialized")
    }
    
    // MARK: - Computed Properties
    
    /// Current authenticated user ID (like posts use authVM.userId)
    private var currentUserId: UUID? {
        authVM?.userId
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        authVM?.isLoggedIn ?? false
    }
    
    // MARK: - Public Methods
    
    /// Load all threads for the current authenticated user
    func loadThreads() async {
        guard let userId = currentUserId else {
            errorMessage = "Please log in to view your conversations."
            print("⚠️ Cannot load threads: User not authenticated")
            return
        }
        
        isLoadingThreads = true
        errorMessage = nil
        
        do {
            threads = try await SupabaseService.shared.fetchThreadsForUser(userId: userId)
            print("✅ Loaded \(threads.count) threads for user \(userId)")
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            print("❌ Error loading threads: \(error)")
        }
        
        isLoadingThreads = false
    }
    
    /// Load messages for a specific thread
    func loadMessages(for thread: ThreadWithDetails) async {
        currentThread = thread
        isLoadingMessages = true
        errorMessage = nil
        
        do {
            let messages = try await SupabaseService.shared.fetchMessages(threadId: thread.id)
            currentThreadMessages = messages
            print("✅ Loaded \(messages.count) messages for thread \(thread.id)")
            
            // Start polling for new messages
            startMessagePolling()
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            print("❌ Error loading messages: \(error)")
        }
        
        isLoadingMessages = false
    }
    
    /// Send a new message
    func sendMessage(text: String, to receiverId: UUID, postId: UUID) async {
        guard let senderId = currentUserId else {
            errorMessage = "Please log in to send messages."
            print("⚠️ Cannot send message: User not authenticated")
            return
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSendingMessage = true
        errorMessage = nil
        
        do {
            let newMessage = try await SupabaseService.shared.sendMessage(
                senderId: senderId,
                receiverId: receiverId,
                postId: postId,
                messageText: text
            )
            
            // Add the new message to the current thread
            currentThreadMessages.append(newMessage)
            print("✅ Message sent successfully")
            
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            print("❌ Error sending message: \(error)")
        }
        
        isSendingMessage = false
    }
    
    /// Create a new thread for a post
    func createThread(postId: UUID, sellerId: UUID) async -> UUID? {
        guard let buyerId = currentUserId else {
            errorMessage = "Please log in to start a conversation."
            print("⚠️ Cannot create thread: User not authenticated")
            return nil
        }
        
        do {
            let threadId = try await SupabaseService.shared.createThread(
                postId: postId,
                buyerId: buyerId,
                sellerId: sellerId
            )
            
            print("✅ Thread created: \(threadId)")
            
            // Reload threads to show the new conversation
            await loadThreads()
            
            return threadId
            
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            print("❌ Error creating thread: \(error)")
            return nil
        }
    }
    
    /// Start a conversation about a post
    func startConversation(post: Post) async {
        guard let threadId = await createThread(postId: post.id, sellerId: post.userId) else {
            return
        }
        
        // Find the newly created thread
        if let thread = threads.first(where: { $0.id == threadId }) {
            await loadMessages(for: thread)
        }
    }
    
    /// Refresh the current thread (manual refresh)
    func refreshCurrentThread() async {
        guard let thread = currentThread else { return }
        await loadMessages(for: thread)
    }
    
    /// Check if message is from current authenticated user
    func isMessageFromCurrentUser(_ message: Message) -> Bool {
        return message.senderId == currentUserId
    }
    
    // MARK: - Real-time Updates (Simplified Polling)
    
    /// Start polling for new messages
    private func startMessagePolling() {
        stopMessagePolling()
        
        messagePollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshMessages()
            }
        }
        
        print("📡 Started message polling")
    }
    
    /// Stop polling for messages
    private func stopMessagePolling() {
        messagePollingTimer?.invalidate()
        messagePollingTimer = nil
    }
    
    /// Start polling for thread updates
    func startThreadPolling() {
        stopThreadPolling()
        
        threadPollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval * 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshThreads()
            }
        }
        
        print("📡 Started thread polling")
    }
    
    /// Stop polling for threads
    private func stopThreadPolling() {
        threadPollingTimer?.invalidate()
        threadPollingTimer = nil
    }
    
    /// Stop all polling
    func stopPolling() {
        stopMessagePolling()
        stopThreadPolling()
        print("📡 Stopped all polling")
    }
    
    /// Refresh messages silently (for polling)
    private func refreshMessages() async {
        guard let thread = currentThread else { return }
        
        do {
            let messages = try await SupabaseService.shared.fetchMessages(threadId: thread.id)
            
            // Only update if we got new messages
            if messages.count > currentThreadMessages.count {
                currentThreadMessages = messages
                print("🔄 Refreshed messages: \(messages.count) total")
            }
        } catch {
            print("⚠️ Silent refresh failed: \(error)")
        }
    }
    
    /// Refresh threads silently (for polling)
    private func refreshThreads() async {
        guard let userId = currentUserId else { return }
        
        do {
            let updatedThreads = try await SupabaseService.shared.fetchThreadsForUser(userId: userId)
            
            // Only update if thread count changed
            if updatedThreads.count != threads.count {
                threads = updatedThreads
                print("🔄 Refreshed threads: \(updatedThreads.count) total")
            }
        } catch {
            print("⚠️ Silent thread refresh failed: \(error)")
        }
    }
    
    /// Get thread count for stats
    func getThreadCount() -> Int {
        return threads.count
    }
}
