import Foundation
import Supabase
import UIKit

final class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient
    
    private init() {
        let contents: String
        
        guard let path = Bundle.main.path(forResource: "App.env", ofType: nil) else {
            fatalError("❌ Missing .env file in bundle")
        }
        
        do {
            contents = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            fatalError("❌ Failed to read App.env file: \(error.localizedDescription)")
        }
        
        let url = SupabaseService.getEnvValue(from: contents, for: "SUPABASE_URL")
        let key = SupabaseService.getEnvValue(from: contents, for: "SUPABASE_ANON_KEY")
    
        guard let supabaseURL = URL(string: url) else {
            fatalError("❌ Invalid Supabase URL in .env file")
        }
        
        let authOptions = SupabaseClientOptions.AuthOptions(
            redirectToURL: nil,
            storageKey: nil,
            flowType: AuthClient.Configuration.defaultFlowType,
            encoder: AuthClient.Configuration.jsonEncoder,
            decoder: AuthClient.Configuration.jsonDecoder,
            autoRefreshToken: true,
            emitLocalSessionAsInitialSession: true,
            accessToken: nil
        )
        
        let options = SupabaseClientOptions(
            db: .init(),
            auth: authOptions,
            global: .init(),
            functions: .init(),
            realtime: .init(),
            storage: .init()
        )
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key,
            options: options
        )
        print("✅ Initialized Supabase client with configuration from App.env file (emitLocalSessionAsInitialSession = true)")
    }
    
    private static func getEnvValue(from contents: String, for key: String) -> String {
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    return value
                }
            }
        }
        fatalError("❌ Missing \(key) in .env file")
    }
    
    // MARK: - Diagnostics
    func testConnection() async throws -> Bool {
        do {
            print("🔄 Testing connection to Supabase...")
            let data: [User] = try await client.from("profiles")
                .select()
                .limit(1)
                .execute()
                .value
            
            print("✅ Successfully connected to Supabase!")
            print("✅ Successfully verified 'profiles' table exists")
            
            if let firstUser = data.first {
                print("""
                    📝 Sample profile data:
                    - Username: \(firstUser.username)
                    - Role: \(firstUser.role)
                    - Location: \(firstUser.location ?? "Not set")
                    - Contact: \(firstUser.contactInfo ?? "Not set")
                    - Created: \(firstUser.createdAt)
                    """)
            }
            
            return true
        } catch let error as PostgrestError {
            print("❌ Database error: \(error.message)")
            if let hint = error.hint {
                print("💡 Hint: \(hint)")
            }
            return false
        } catch {
            print("❌ Connection error: \(error)")
            return false
        }
    }
    
    func fetchUsers() async throws -> [User] {
        do {
            print("🔄 Fetching users from profiles table...")
            let users: [User] = try await client.from("profiles")
                .select()
                .order("username")
                .execute()
                .value
            
            print("""
                ✅ Successfully fetched \(users.count) users:
                \(users.map { "- \($0.username) (\($0.role))" }.joined(separator: "\n"))
                """)
            return users
            
        } catch let error as PostgrestError {
            print("❌ Database error: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            throw error
        } catch {
            print("❌ Unknown error: \(error)")
            throw error
        }
    }
    
    // MARK: - Auth / Profile
    func getCurrentUser() async throws -> User? {
        do {
            print("🔄 Fetching current authenticated user...")
            guard let session = try? await client.auth.session else {
                print("⚠️ No authenticated session found")
                return nil
            }
            let userId = session.user.id
            print("✅ Current user ID: \(userId)")
            
            let profile: User = try await client.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            print("✅ Successfully fetched current user profile: \(profile.username)")
            return profile
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching current user: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Error fetching current user: \(error)")
            throw error
        }
    }
    
    // MARK: - User Stats
    func fetchUserStats(userId: UUID) async throws -> UserStats {
        do {
            print("🔄 Fetching user stats for user: \(userId)")
            struct SimplePost: Codable { let id: UUID; let user_id: UUID }
            let listedItemsResponse: [SimplePost] = try await client.from("posts")
                .select("id, user_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let listedCount = listedItemsResponse.count
            
            let savedItemsResponse: [SavedItem] = try await client.from("saved_items")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let savedCount = savedItemsResponse.count
            
            let threadsResponse: [Thread] = try await client.from("threads")
                .select()
                .or("buyer_id.eq.\(userId.uuidString),seller_id.eq.\(userId.uuidString)")
                .execute()
                .value
            let chatsCount = threadsResponse.count
            
            let stats = UserStats(
                listedItemsCount: listedCount,
                savedItemsCount: savedCount,
                chatsCount: chatsCount,
                completedTransactions: 0,
                totalEarnings: 0.0
            )
            print("✅ Successfully fetched user stats: \(listedCount) listed, \(savedCount) saved, \(chatsCount) chats")
            return stats
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching user stats: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error fetching user stats: \(error)")
            throw error
        }
    }
    
    struct SavedItem: Codable {
        let id: UUID
        let user_id: UUID
        let post_id: UUID
    }
    
    struct Thread: Codable {
        let id: UUID
        let buyer_id: UUID
        let seller_id: UUID
        let post_id: UUID
        let created_at: Date
    }
    
    // MARK: - Posts (browse/search)
    func fetchPosts(limit: Int = 20, offset: Int = 0, sortOption: SortOption = .newest) async throws -> [Post] {
        do {
            print("🔄 Fetching posts (limit: \(limit), offset: \(offset), sort: \(sortOption.rawValue))...")
            
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?
                struct ProfileInfo: Codable { let username: String }
            }
            
            let postsWithProfiles: [PostWithProfile] = try await client.from("posts")
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
                .eq("status", value: "active")
                .order(sortOption.columnName, ascending: sortOption.isAscending)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            let posts = postsWithProfiles.compactMap { p -> Post? in
                guard let profileInfo = p.profiles else {
                    print("⚠️ Warning: Post \(p.id) has no associated profile, skipping")
                    return nil
                }
                return Post(
                    id: p.id,
                    title: p.title,
                    description: p.description,
                    price: p.price,
                    category: p.category,
                    userId: p.user_id,
                    sellerName: profileInfo.username,
                    status: p.status,
                    createdAt: p.created_at
                )
            }
            print("✅ Successfully fetched \(posts.count) posts")
            return posts
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching posts: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error fetching posts: \(error)")
            throw error
        }
    }
    
    func searchPosts(query: String, filters: SearchFilters, limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        do {
            print("🔄 Searching posts with query: '\(query)' and filters (limit: \(limit), offset: \(offset))")
            
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?
                struct ProfileInfo: Codable { let username: String }
            }
            
            var queryBuilder = client.from("posts")
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
                .eq("status", value: "active")
            
            if !query.isEmpty {
                queryBuilder = queryBuilder.or("title.ilike.%\(query)%,description.ilike.%\(query)%")
            }
            if let category = filters.category {
                queryBuilder = queryBuilder.eq("category", value: category.rawValue)
            }
            if let minPrice = filters.minPrice {
                queryBuilder = queryBuilder.gte("price", value: minPrice)
            }
            if let maxPrice = filters.maxPrice {
                queryBuilder = queryBuilder.lte("price", value: maxPrice)
            }
            if let campus = filters.campus {
                queryBuilder = queryBuilder.eq("campus_location", value: campus.databaseValue)
            }
            
            let postsWithProfiles: [PostWithProfile] = try await queryBuilder
                .order(filters.sortOption.columnName, ascending: filters.sortOption.isAscending)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            let posts = postsWithProfiles.compactMap { p -> Post? in
                guard let profileInfo = p.profiles else {
                    print("⚠️ Warning: Post \(p.id) has no associated profile, skipping")
                    return nil
                }
                return Post(
                    id: p.id,
                    title: p.title,
                    description: p.description,
                    price: p.price,
                    category: p.category,
                    userId: p.user_id,
                    sellerName: profileInfo.username,
                    status: p.status,
                    createdAt: p.created_at
                )
            }
            print("✅ Search returned \(posts.count) posts")
            return posts
            
        } catch let error as PostgrestError {
            print("❌ Database error searching posts: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error searching posts: \(error)")
            throw error
        }
    }
    
    func fetchPostsByCategory(_ category: ProductCategory, sortOption: SortOption = .newest) async throws -> [Post] {
        do {
            print("🔄 Fetching posts for category: \(category.rawValue)")
            
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?
                struct ProfileInfo: Codable { let username: String }
            }
            
            let postsWithProfiles: [PostWithProfile] = try await client.from("posts")
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
                .eq("status", value: "active")
                .eq("category", value: category.rawValue)
                .order(sortOption.columnName, ascending: sortOption.isAscending)
                .execute()
                .value
            
            let posts = postsWithProfiles.compactMap { p -> Post? in
                guard let profileInfo = p.profiles else {
                    print("⚠️ Warning: Post \(p.id) has no associated profile, skipping")
                    return nil
                }
                return Post(
                    id: p.id,
                    title: p.title,
                    description: p.description,
                    price: p.price,
                    category: p.category,
                    userId: p.user_id,
                    sellerName: profileInfo.username,
                    status: p.status,
                    createdAt: p.created_at
                )
            }
            print("✅ Found \(posts.count) posts in category \(category.rawValue)")
            return posts
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching posts by category: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error fetching posts: \(error)")
            throw error
        }
    }
    
    // MARK: - User-specific posts/saved
    func fetchUserPosts(userId: UUID) async throws -> [Post] {
        print("🔄 Fetching posts for user: \(userId)")
        let posts: [Post] = try await client.from("posts")
            .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
            .value
        print("✅ Successfully fetched \(posts.count) posts for user")
        return posts
    }
    
    func fetchSavedItems(userId: UUID) async throws -> [Post] {
        print("🔄 Fetching saved posts for user: \(userId)")
        struct SavedItemWithPost: Codable {
            let post_id: UUID
            let posts: PostData?
            struct PostData: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?
                struct ProfileInfo: Codable { let username: String }
            }
        }
        let savedItemsResponse: [SavedItemWithPost] = try await client.from("saved_items")
            .select("post_id, posts!saved_items_post_id_fkey(id, title, description, price, category, user_id, status, created_at, profiles(username))")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        print("DEBUG: Fetched \(savedItemsResponse.count) saved_items records")
        let savedPosts = savedItemsResponse.compactMap { item -> Post? in
            guard let postData = item.posts else {
                print("⚠️ Saved item has no post data, skipping")
                return nil
            }
            guard let profileInfo = postData.profiles else {
                print("⚠️ Post \(postData.id) has no profile, skipping")
                return nil
            }
            return Post(
                id: postData.id,
                title: postData.title,
                description: postData.description,
                price: postData.price,
                category: postData.category,
                userId: postData.user_id,
                sellerName: profileInfo.username,
                status: postData.status,
                createdAt: postData.created_at
            )
        }
        print("✅ Successfully fetched \(savedPosts.count) saved posts for user")
        return savedPosts
    }
    
    // MARK: - Saved Items (save/unsave/isSaved)
    func savePost(userId: UUID, postId: UUID) async throws {
        do {
            print("🔄 Saving post \(postId) for user \(userId)")
            struct SavedInsert: Codable {
                let user_id: String
                let post_id: String
            }
            let payload = SavedInsert(user_id: userId.uuidString, post_id: postId.uuidString)
            _ = try await client.from("saved_items")
                .insert(payload)
                .execute()
            print("✅ Post saved")
        } catch let error as PostgrestError {
            print("❌ Database error saving post: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error saving post: \(error)")
            throw error
        }
    }
    
    func unsavePost(userId: UUID, postId: UUID) async throws {
        do {
            print("🔄 Removing saved post \(postId) for user \(userId)")
            _ = try await client.from("saved_items")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("post_id", value: postId.uuidString)
                .execute()
            print("✅ Post unsaved")
        } catch let error as PostgrestError {
            print("❌ Database error unsaving post: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error unsaving post: \(error)")
            throw error
        }
    }
    
    func isPostSaved(userId: UUID, postId: UUID) async throws -> Bool {
        do {
            struct SavedRow: Codable { let id: UUID }
            let rows: [SavedRow] = try await client.from("saved_items")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .eq("post_id", value: postId.uuidString)
                .limit(1)
                .execute()
                .value
            return !rows.isEmpty
        } catch let error as PostgrestError {
            print("❌ Database error checking saved status: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error checking saved status: \(error)")
            throw error
        }
    }
    
    // MARK: - Messaging
    func fetchThreadsForUser(userId: UUID) async throws -> [ThreadWithDetails] {
        do {
            print("🔄 Fetching threads for user: \(userId)")
            let threadsResponse: [Thread] = try await client.from("threads")
                .select()
                .or("buyer_id.eq.\(userId.uuidString),seller_id.eq.\(userId.uuidString)")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            var threadsWithDetails: [ThreadWithDetails] = []
            for thread in threadsResponse {
                struct PostTitle: Codable { let title: String }
                let postResult: PostTitle? = try? await client.from("posts")
                    .select("title")
                    .eq("id", value: thread.post_id.uuidString)
                    .single()
                    .execute()
                    .value
                
                struct ProfileRow: Codable { let username: String; let avatar_path: String? }
                let buyerProfile: ProfileRow? = try? await client.from("profiles")
                    .select("username, avatar_path")
                    .eq("id", value: thread.buyer_id.uuidString)
                    .single()
                    .execute()
                    .value
                let sellerProfile: ProfileRow? = try? await client.from("profiles")
                    .select("username, avatar_path")
                    .eq("id", value: thread.seller_id.uuidString)
                    .single()
                    .execute()
                    .value
                
                guard let postTitle = postResult?.title,
                      let buyerUsername = buyerProfile?.username,
                      let sellerUsername = sellerProfile?.username else {
                    continue
                }
                
                let isCurrentUserBuyer = thread.buyer_id == userId
                let otherPersonName = isCurrentUserBuyer ? sellerUsername : buyerUsername
                let otherPersonId = isCurrentUserBuyer ? thread.seller_id : thread.buyer_id
                let otherPersonAvatarPath = isCurrentUserBuyer ? sellerProfile?.avatar_path : buyerProfile?.avatar_path
                
                struct LatestMessageRow: Codable {
                    let message: String
                    let created_at: Date
                }
                let latestMessage: LatestMessageRow? = try? await client.from("messages")
                    .select("message, created_at")
                    .eq("thread_id", value: thread.id.uuidString)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .single()
                    .execute()
                    .value
                
                var threadWithDetails = ThreadWithDetails(
                    id: thread.id,
                    postId: thread.post_id,
                    postTitle: postTitle,
                    buyerId: thread.buyer_id,
                    sellerId: thread.seller_id,
                    otherPersonName: otherPersonName,
                    otherPersonId: otherPersonId,
                    createdAt: thread.created_at
                )
                if let latestMessage {
                    threadWithDetails.lastMessagePreview = latestMessage.message
                    threadWithDetails.lastMessageTime = latestMessage.created_at
                }
                threadWithDetails.otherPersonAvatarPath = otherPersonAvatarPath
                print("🧩 Thread \(thread.id) other=\(otherPersonName) avatarPath=\(otherPersonAvatarPath ?? "nil")")
                
                threadsWithDetails.append(threadWithDetails)
            }
            threadsWithDetails.sort { lhs, rhs in
                let lhsDate = lhs.lastMessageTime ?? lhs.createdAt
                let rhsDate = rhs.lastMessageTime ?? rhs.createdAt
                return lhsDate > rhsDate
            }
            print("✅ Successfully fetched \(threadsWithDetails.count) threads with details")
            return threadsWithDetails
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching threads: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error fetching threads: \(error)")
            throw error
        }
    }
    
    func fetchMessages(threadId: UUID) async throws -> [Message] {
        do {
            print("🔄 Fetching messages for thread: \(threadId)")
            struct MessageResponse: Codable {
                let id: UUID
                let sender_id: UUID
                let receiver_id: UUID
                let post_id: UUID
                let thread_id: UUID
                let message: String
                let created_at: Date
                let sender_profile: ProfileInfo?
                struct ProfileInfo: Codable { let username: String }
            }
            
            let messagesResponse: [MessageResponse] = try await client.from("messages")
                .select("""
                    id, sender_id, receiver_id, post_id, thread_id, message, created_at,
                    sender_profile:profiles!messages_sender_id_fkey(username)
                    """)
                .eq("thread_id", value: threadId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            let messages = messagesResponse.compactMap { msg -> Message? in
                guard let senderProfile = msg.sender_profile else {
                    print("⚠️ Warning: Message \(msg.id) has no sender profile")
                    return nil
                }
                return Message(
                    id: msg.id,
                    senderId: msg.sender_id,
                    receiverId: msg.receiver_id,
                    postId: msg.post_id,
                    message: msg.message,
                    senderName: senderProfile.username,
                    createdAt: msg.created_at
                )
            }
            print("✅ Successfully fetched \(messages.count) messages")
            return messages
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching messages: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error fetching messages: \(error)")
            throw error
        }
    }
    
    // MARK: - Send / Threads
    func sendMessage(senderId: UUID, receiverId: UUID, postId: UUID, threadId: UUID, messageText: String) async throws -> Message {
        do {
            print("🔄 Sending message from \(senderId) to \(receiverId) in thread \(threadId)")
            struct MessageInsert: Codable {
                let sender_id: String
                let receiver_id: String
                let post_id: String
                let thread_id: String
                let message: String
            }
            struct MessageResponse: Codable {
                let id: UUID
                let sender_id: UUID
                let receiver_id: UUID
                let post_id: UUID
                let thread_id: UUID
                let message: String
                let created_at: Date
            }
            let newMessage = MessageInsert(
                sender_id: senderId.uuidString,
                receiver_id: receiverId.uuidString,
                post_id: postId.uuidString,
                thread_id: threadId.uuidString,
                message: messageText
            )
            let response: MessageResponse = try await client.from("messages")
                .insert(newMessage)
                .select()
                .single()
                .execute()
                .value
            
            let sender: User = try await client.from("profiles")
                .select()
                .eq("id", value: senderId.uuidString)
                .single()
                .execute()
                .value
            
            let message = Message(
                id: response.id,
                senderId: response.sender_id,
                receiverId: response.receiver_id,
                postId: response.post_id,
                message: response.message,
                senderName: sender.username,
                createdAt: response.created_at
            )
            print("✅ Message sent successfully")
            return message
            
        } catch let error as PostgrestError {
            print("❌ Database error sending message: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error sending message: \(error)")
            throw error
        }
    }
    
    func createThread(postId: UUID, buyerId: UUID, sellerId: UUID) async throws -> UUID {
        do {
            print("🔄 Creating new thread for post: \(postId)")
            struct ExistingThread: Codable { let id: UUID }
            let existingThreads: [ExistingThread] = try await client.from("threads")
                .select("id")
                .eq("post_id", value: postId.uuidString)
                .eq("buyer_id", value: buyerId.uuidString)
                .eq("seller_id", value: sellerId.uuidString)
                .execute()
                .value
            if let existing = existingThreads.first {
                print("✅ Thread already exists: \(existing.id)")
                return existing.id
            }
            struct ThreadInsert: Codable { let post_id: String; let buyer_id: String; let seller_id: String }
            struct ThreadResponse: Codable { let id: UUID }
            let newThread = ThreadInsert(post_id: postId.uuidString, buyer_id: buyerId.uuidString, seller_id: sellerId.uuidString)
            let response: ThreadResponse = try await client.from("threads")
                .insert(newThread)
                .select("id")
                .single()
                .execute()
                .value
            print("✅ New thread created: \(response.id)")
            return response.id
            
        } catch let error as PostgrestError {
            print("❌ Database error creating thread: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error creating thread: \(error)")
            throw error
        }
    }
    
    func subscribeToMessages(threadId: UUID, onMessage: @escaping (Message) -> Void) async throws {
        print("📡 Real-time message subscription would be set up here for thread: \(threadId)")
    }
    
    // MARK: - Posts CRUD used by ListingsViewModel
    func createPost(
        title: String,
        description: String,
        price: Double,
        category: String,
        userId: UUID,
        campusLocation: String? = nil,
        imageUrls: [String]? = nil
    ) async throws -> Post {
        do {
            print("🔄 Creating new post: '\(title)' by user \(userId)")
            struct PostInsert: Codable {
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: String
                let status: String
                let campus_location: String?
            }
            let postInsert = PostInsert(
                title: title,
                description: description,
                price: price,
                category: category,
                user_id: userId.uuidString,
                status: "active",
                campus_location: campusLocation
            )
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?
                struct ProfileInfo: Codable { let username: String }
            }
            let response: PostWithProfile = try await client
                .from("posts")
                .insert(postInsert)
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
                .single()
                .execute()
                .value
            
            let post = Post(
                id: response.id,
                title: response.title,
                description: response.description,
                price: response.price,
                category: response.category,
                userId: response.user_id,
                sellerName: response.profiles?.username ?? "Unknown User",
                status: response.status,
                createdAt: response.created_at
            )
            print("✅ Post created successfully with ID: \(post.id)")
            return post
            
        } catch let error as PostgrestError {
            print("❌ Database error creating post: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error creating post: \(error)")
            throw error
        }
    }
    
    func updatePost(
        id: UUID,
        title: String? = nil,
        description: String? = nil,
        price: Double? = nil,
        category: String? = nil,
        campusLocation: String? = nil,
        status: String? = nil
    ) async throws -> Post {
        do {
            print("🔄 Updating post: \(id)")
            struct PostUpdate: Codable {
                let title: String?
                let description: String?
                let price: Double?
                let category: String?
                let campus_location: String?
                let status: String?
            }
            let updates = PostUpdate(
                title: title,
                description: description,
                price: price,
                category: category,
                campus_location: campusLocation,
                status: status
            )
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?
                struct ProfileInfo: Codable { let username: String }
            }
            let response: PostWithProfile = try await client
                .from("posts")
                .update(updates)
                .eq("id", value: id.uuidString)
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
                .single()
                .execute()
                .value
            
            let post = Post(
                id: response.id,
                title: response.title,
                description: response.description,
                price: response.price,
                category: response.category,
                userId: response.user_id,
                sellerName: response.profiles?.username ?? "Unknown User",
                status: response.status,
                createdAt: response.created_at
            )
            print("✅ Post updated successfully: \(post.id)")
            return post
            
        } catch let error as PostgrestError {
            print("❌ Database error updating post: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error updating post: \(error)")
            throw error
        }
    }
    
    func deletePost(id: UUID) async throws {
        do {
            print("🔄 Soft deleting post: \(id)")
            _ = try await client
                .from("posts")
                .update(["status": "hidden"])
                .eq("id", value: id.uuidString)
                .execute()
            print("✅ Post marked as hidden (soft delete)")
        } catch let error as PostgrestError {
            print("❌ Database error deleting post: \(error.message)")
            if let hint = error.hint { print("💡 Hint: \(hint)") }
            throw error
        } catch {
            print("❌ Unknown error deleting post: \(error)")
            throw error
        }
    }
    
    // MARK: - Storage (profile avatar)
    func uploadProfileImage(image: UIImage, userId: UUID) async throws -> String {
        print("🖼️ [Avatar] Starting uploadProfileImage for userId=\(userId)")
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            print("❌ [Avatar] Failed to encode image as JPEG")
            throw NSError(domain: "ImageEncoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }
        print("ℹ️ [Avatar] Encoded image size: \(data.count) bytes")
        let bucket = "profile_picture"
        let timestamp = Int(Date().timeIntervalSince1970)
        let objectPath = "users/\(userId.uuidString)/profile-\(timestamp).jpg"
        print("ℹ️ [Avatar] Uploading to bucket='\(bucket)' path='\(objectPath)' (upsert=false, unique filename)")
        try await uploadImageData(data: data, bucket: bucket, path: objectPath, contentType: "image/jpeg", upsert: false)
        print("✅ [Avatar] Uploaded profile image to \(bucket)/\(objectPath)")
        return objectPath
    }
    
    // Return URL? and swallow cancellations to allow fallback
    func getSignedURL(bucket: String = "profile_picture", path: String, expiresInSeconds: Int = 3600) async throws -> URL? {
        print("🔏 [Avatar] Generating signed URL for bucket='\(bucket)' path='\(path)' expiresIn=\(expiresInSeconds)s")
        do {
            let signed = try await client.storage
                .from(bucket)
                .createSignedURL(path: path, expiresIn: expiresInSeconds)
            print("✅ [Avatar] Signed URL generated")
            return signed
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("ℹ️ [Avatar] Signing request cancelled (-999); will allow fallback")
                return nil
            }
            throw error
        }
    }
    
    func getUserAvatarURL(userId: UUID, expiresInSeconds: Int = 3600) async throws -> URL? {
        if let path = try await fetchProfileAvatarPath(userId: userId) {
            return try await getSignedURL(path: path, expiresInSeconds: expiresInSeconds)
        }
        return nil
    }
    
    func updateProfileAvatarPath(userId: UUID, avatarPath: String) async throws {
        print("📝 [Avatar] Updating profiles.avatar_path for userId=\(userId) path='\(avatarPath)'")
        struct UpdatePayload: Codable {
            let avatar_path: String
        }
        let payload = UpdatePayload(avatar_path: avatarPath)
        do {
            _ = try await client
                .from("profiles")
                .update(payload)
                .eq("id", value: userId.uuidString)
                .execute()
            print("✅ [Avatar] profiles.avatar_path updated successfully")
        } catch let error as PostgrestError {
            print("❌ [Avatar] Database error updating avatar_path: \(error.message)")
            if let hint = error.hint { print("💡 [Avatar] Hint: \(hint)") }
            throw error
        } catch {
            print("❌ [Avatar] Unknown error updating avatar_path: \(error)")
            throw error
        }
    }
    
    func fetchProfileAvatarPath(userId: UUID) async throws -> String? {
        print("🔎 [Avatar] Fetching profiles.avatar_path for userId=\(userId)")
        do {
            guard let session = try? await client.auth.session, !session.isExpired else {
                print("ℹ️ [Avatar] Skipping avatar_path fetch: no active session")
                return nil
            }
        }
        struct AvatarRow: Codable { let avatar_path: String? }
        do {
            let row: AvatarRow = try await client
                .from("profiles")
                .select("avatar_path")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            print("ℹ️ [Avatar] Current avatar_path: \(row.avatar_path ?? "nil")")
            return row.avatar_path
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("ℹ️ [Avatar] Request was cancelled (-999); likely superseded by a newer one")
                return nil
            }
            print("❌ [Avatar] Error fetching avatar_path: \(error)")
            return nil
        }
    }
    
    private func uploadImageData(data: Data, bucket: String, path: String, contentType: String, upsert: Bool = false) async throws {
        let options = FileOptions(contentType: contentType, upsert: upsert)
        _ = try await client.storage
            .from(bucket)
            .upload(path: path, file: data, options: options)
    }
    
    // MARK: - Messaging deletions
    func deleteMessage(messageId: UUID, senderId: UUID) async throws {
        do {
            _ = try await client
                .from("messages")
                .delete()
                .eq("id", value: messageId.uuidString)
                .eq("sender_id", value: senderId.uuidString)
                .execute()
            print("✅ Deleted message \(messageId) by sender \(senderId)")
        } catch let error as PostgrestError {
            print("❌ Database error deleting message: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error deleting message: \(error)")
            throw error
        }
    }
    
    func deleteMessagesInThread(threadId: UUID) async throws {
        do {
            _ = try await client
                .from("messages")
                .delete()
                .eq("thread_id", value: threadId.uuidString)
                .execute()
            print("✅ Deleted all messages in thread \(threadId)")
        } catch let error as PostgrestError {
            print("❌ Database error deleting messages in thread: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error deleting messages in thread: \(error)")
            throw error
        }
    }
    
    func deleteThread(threadId: UUID) async throws {
        do {
            _ = try await client
                .from("threads")
                .delete()
                .eq("id", value: threadId.uuidString)
                .execute()
            print("✅ Deleted thread \(threadId)")
        } catch let error as PostgrestError {
            print("❌ Database error deleting thread: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error deleting thread: \(error)")
            throw error
        }
    }
    
    func fetchUserStatsForTesting(userIdString: String) async throws -> (user: User, stats: UserStats) {
        guard let userId = UUID(uuidString: userIdString) else {
            throw NSError(domain: "Invalid UUID", code: 400, userInfo: nil)
        }
        let user: User = try await client.from("profiles")
            .select()
            .eq("id", value: userIdString)
            .single()
            .execute()
            .value
        let stats = try await fetchUserStats(userId: userId)
        return (user, stats)
    }
}
