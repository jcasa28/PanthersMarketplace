import Foundation
import Supabase

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
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key
        )
        print("✅ Initialized Supabase client with configuration from App.env file")
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
                .order("username")  // Sort by username for consistent display
                .execute()
                .value
            
            print("""
                ✅ Successfully fetched \(users.count) users:
                \(users.map { "- \($0.username) (\($0.role))" }.joined(separator: "\n"))
                """)
            return users
            
        } catch let error as PostgrestError {
            print("❌ Database error: \(error.message)")
            if let hint = error.hint {
                print("💡 Hint: \(hint)")
            }
            throw error
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            throw error
        } catch {
            print("❌ Unknown error: \(error)")
            throw error
        }
    }
    
    // MARK: - Posts Methods
    func fetchPosts(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        do {
            print("🔄 Fetching posts from posts table (limit: \(limit), offset: \(offset))...")
            
            // Custom struct to handle the joined data from Supabase
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?  // Made optional to handle null profiles
                
                struct ProfileInfo: Codable {
                    let username: String
                }
            }
            
            let postsWithProfiles: [PostWithProfile] = try await client.from("posts")
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            // Convert to Post objects, filtering out posts without valid profiles
            let posts = postsWithProfiles.compactMap { postWithProfile -> Post? in
                guard let profileInfo = postWithProfile.profiles else {
                    print("⚠️ Warning: Post \(postWithProfile.id) has no associated profile, skipping")
                    return nil
                }
                
                return Post(
                    id: postWithProfile.id,
                    title: postWithProfile.title,
                    description: postWithProfile.description,
                    price: postWithProfile.price,
                    category: postWithProfile.category,
                    userId: postWithProfile.user_id,
                    sellerName: profileInfo.username,
                    status: postWithProfile.status,
                    createdAt: postWithProfile.created_at
                )
            }
            
            print("✅ Successfully fetched \(posts.count) posts")
            return posts
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching posts: \(error.message)")
            if let hint = error.hint {
                print("💡 Hint: \(hint)")
            }
            throw error
        } catch {
            print("❌ Unknown error fetching posts: \(error)")
            throw error
        }
    }
    
    func searchPosts(query: String, filters: SearchFilters, limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        do {
            print("🔄 Searching posts with query: '\(query)' and filters (limit: \(limit), offset: \(offset))")
            
            // Custom struct to handle the joined data from Supabase
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?  // Made optional to handle null profiles
                
                struct ProfileInfo: Codable {
                    let username: String
                    let location: String?
                }
            }
            
            var queryBuilder = client.from("posts")
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username, location)")
                .eq("status", value: "active")
            
            // Apply text search if query is not empty
            if !query.isEmpty {
                queryBuilder = queryBuilder.or("title.ilike.%\(query)%,description.ilike.%\(query)%")
            }
            
            // Apply category filter
            if let category = filters.category {
                queryBuilder = queryBuilder.eq("category", value: category.rawValue)
            }
            
            // Apply price filters
            if let minPrice = filters.minPrice {
                queryBuilder = queryBuilder.gte("price", value: minPrice)
            }
            
            if let maxPrice = filters.maxPrice {
                queryBuilder = queryBuilder.lte("price", value: maxPrice)
            }
            
            // Note: Campus filter will be applied after fetching results
            // because Supabase doesn't support filtering on joined columns directly
            
            let postsWithProfiles: [PostWithProfile] = try await queryBuilder
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            // Convert to Post objects, filtering out posts without valid profiles
            var posts = postsWithProfiles.compactMap { postWithProfile -> Post? in
                guard let profileInfo = postWithProfile.profiles else {
                    print("⚠️ Warning: Post \(postWithProfile.id) has no associated profile, skipping")
                    return nil
                }
                
                return Post(
                    id: postWithProfile.id,
                    title: postWithProfile.title,
                    description: postWithProfile.description,
                    price: postWithProfile.price,
                    category: postWithProfile.category,
                    userId: postWithProfile.user_id,
                    sellerName: profileInfo.username,
                    status: postWithProfile.status,
                    createdAt: postWithProfile.created_at
                )
            }
            
            // Apply campus filter after fetching if specified
            if let campus = filters.campus {
                posts = posts.filter { post in
                    // We need to check the location from the fetched profile data
                    if let postWithProfile = postsWithProfiles.first(where: { $0.id == post.id }),
                       let location = postWithProfile.profiles?.location {
                        return location == campus.rawValue
                    }
                    return false
                }
            }
            
            print("✅ Search returned \(posts.count) posts")
            return posts
            
        } catch let error as PostgrestError {
            print("❌ Database error searching posts: \(error.message)")
            if let hint = error.hint {
                print("💡 Hint: \(hint)")
            }
            throw error
        } catch {
            print("❌ Unknown error searching posts: \(error)")
            throw error
        }
    }
    
    func fetchPostsByCategory(_ category: ProductCategory) async throws -> [Post] {
        do {
            print("🔄 Fetching posts for category: \(category.rawValue)")
            
            // Custom struct to handle the joined data from Supabase
            struct PostWithProfile: Codable {
                let id: UUID
                let title: String
                let description: String
                let price: Double
                let category: String
                let user_id: UUID
                let status: String
                let created_at: Date
                let profiles: ProfileInfo?  // Made optional to handle null profiles
                
                struct ProfileInfo: Codable {
                    let username: String
                }
            }
            
            let postsWithProfiles: [PostWithProfile] = try await client.from("posts")
                .select("id, title, description, price, category, user_id, status, created_at, profiles:user_id(username)")
                .eq("status", value: "active")
                .eq("category", value: category.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Convert to Post objects, filtering out posts without valid profiles
            let posts = postsWithProfiles.compactMap { postWithProfile -> Post? in
                guard let profileInfo = postWithProfile.profiles else {
                    print("⚠️ Warning: Post \(postWithProfile.id) has no associated profile, skipping")
                    return nil
                }
                
                return Post(
                    id: postWithProfile.id,
                    title: postWithProfile.title,
                    description: postWithProfile.description,
                    price: postWithProfile.price,
                    category: postWithProfile.category,
                    userId: postWithProfile.user_id,
                    sellerName: profileInfo.username,
                    status: postWithProfile.status,
                    createdAt: postWithProfile.created_at
                )
            }
            
            print("✅ Found \(posts.count) posts in category \(category.rawValue)")
            return posts
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching posts by category: \(error.message)")
            if let hint = error.hint {
                print("💡 Hint: \(hint)")
            }
            throw error
        } catch {
            print("❌ Unknown error fetching posts by category: \(error)")
            throw error
        }
    }
    
    // MARK: - User Profile Methods
    func getCurrentUser() async throws -> User? {
        do {
            print("🔄 Fetching current authenticated user...")
            
            // Try to get the current session from Supabase Auth
            guard let session = try? await client.auth.session else {
                print("⚠️ No authenticated session found")
                return nil
            }
            
            let userId = session.user.id
            
            print("✅ Current user ID: \(userId)")
            
            // Fetch the user's profile from the profiles table
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
            if let hint = error.hint {
                print("💡 Hint: \(hint)")
            }
            throw error
        } catch {
            print("❌ Error fetching current user: \(error)")
            throw error
        }
    }
    
    // MARK: - User Stats Methods
    func fetchUserStats(userId: UUID) async throws -> UserStats {
        do {
            print("🔄 Fetching user stats for user: \(userId)")
            
            // Simple struct for counting posts without needing full Post decoding
            struct SimplePost: Codable {
                let id: UUID
                let user_id: UUID
            }
            
            // Count listed items - only fetch id and user_id to avoid decoding issues
            let listedItemsResponse: [SimplePost] = try await client.from("posts")
                .select("id, user_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let listedCount = listedItemsResponse.count
            
            // Count saved items
            let savedItemsResponse: [SavedItem] = try await client.from("saved_items")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let savedCount = savedItemsResponse.count
            
            // Count threads (chats) where user is buyer or seller
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
            if let hint = error.hint {
                print("💡 Hint: \(hint)")
            }
            throw error
        } catch {
            print("❌ Unknown error fetching user stats: \(error)")
            throw error
        }
    }
    
    // MARK: - Test Methods (for testing without authentication)
    func fetchUserStatsForTesting(userIdString: String) async throws -> (user: User, stats: UserStats) {
        guard let userId = UUID(uuidString: userIdString) else {
            throw NSError(domain: "Invalid UUID", code: 400, userInfo: nil)
        }
        
        // Fetch user profile
        let user: User = try await client.from("profiles")
            .select()
            .eq("id", value: userIdString)
            .single()
            .execute()
            .value
        
        // Fetch stats
        let stats = try await fetchUserStats(userId: userId)
        
        return (user, stats)
    }
    
    // Helper structs for stats queries
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
    }
    
    // MARK: - Messaging Methods
    
    /// Fetch all threads (conversations) for a user
    func fetchThreadsForUser(userId: UUID) async throws -> [ThreadWithDetails] {
        do {
            print("🔄 Fetching threads for user: \(userId)")
            
            struct ThreadResponse: Codable {
                let id: UUID
                let post_id: UUID
                let buyer_id: UUID
                let seller_id: UUID
                let created_at: Date
                let posts: PostInfo?
                let buyer_profile: ProfileInfo?
                let seller_profile: ProfileInfo?
                
                struct PostInfo: Codable {
                    let title: String
                }
                
                struct ProfileInfo: Codable {
                    let username: String
                }
            }
            
            let threadsResponse: [ThreadResponse] = try await client.from("threads")
                .select("""
                    id, post_id, buyer_id, seller_id, created_at,
                    posts!threads_post_id_fkey(title),
                    buyer_profile:profiles!threads_buyer_id_fkey(username),
                    seller_profile:profiles!threads_seller_id_fkey(username)
                    """)
                .or("buyer_id.eq.\(userId.uuidString),seller_id.eq.\(userId.uuidString)")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let threads = threadsResponse.compactMap { thread -> ThreadWithDetails? in
                guard let postInfo = thread.posts,
                      let buyerProfile = thread.buyer_profile,
                      let sellerProfile = thread.seller_profile else {
                    print("⚠️ Warning: Thread \(thread.id) missing related data")
                    return nil
                }
                
                // Determine who the "other" person in the conversation is
                let isCurrentUserBuyer = thread.buyer_id == userId
                let otherPersonName = isCurrentUserBuyer ? sellerProfile.username : buyerProfile.username
                let otherPersonId = isCurrentUserBuyer ? thread.seller_id : thread.buyer_id
                
                return ThreadWithDetails(
                    id: thread.id,
                    postId: thread.post_id,
                    postTitle: postInfo.title,
                    buyerId: thread.buyer_id,
                    sellerId: thread.seller_id,
                    otherPersonName: otherPersonName,
                    otherPersonId: otherPersonId,
                    createdAt: thread.created_at
                )
            }
            
            print("✅ Successfully fetched \(threads.count) threads")
            return threads
            
        } catch let error as PostgrestError {
            print("❌ Database error fetching threads: \(error.message)")
            throw error
        } catch {
            print("❌ Unknown error fetching threads: \(error)")
            throw error
        }
    }
    
    /// Fetch messages for a specific thread
    func fetchMessages(threadId: UUID) async throws -> [Message] {
        do {
            print("🔄 Fetching messages for thread: \(threadId)")
            
            struct MessageResponse: Codable {
                let id: UUID
                let sender_id: UUID
                let receiver_id: UUID
                let post_id: UUID
                let message: String
                let created_at: Date
                let sender_profile: ProfileInfo?
                
                struct ProfileInfo: Codable {
                    let username: String
                }
            }
            
            // First, get the thread to find the post_id
            let thread: Thread = try await client.from("threads")
                .select()
                .eq("id", value: threadId.uuidString)
                .single()
                .execute()
                .value
            
            // Fetch messages for this post between the buyer and seller
            let messagesResponse: [MessageResponse] = try await client.from("messages")
                .select("""
                    id, sender_id, receiver_id, post_id, message, created_at,
                    sender_profile:profiles!messages_sender_id_fkey(username)
                    """)
                .eq("post_id", value: thread.post_id.uuidString)
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
    
    /// Send a new message in a thread
    func sendMessage(senderId: UUID, receiverId: UUID, postId: UUID, messageText: String) async throws -> Message {
        do {
            print("🔄 Sending message from \(senderId) to \(receiverId)")
            
            struct MessageInsert: Codable {
                let sender_id: String
                let receiver_id: String
                let post_id: String
                let message: String
            }
            
            struct MessageResponse: Codable {
                let id: UUID
                let sender_id: UUID
                let receiver_id: UUID
                let post_id: UUID
                let message: String
                let created_at: Date
            }
            
            let newMessage = MessageInsert(
                sender_id: senderId.uuidString,
                receiver_id: receiverId.uuidString,
                post_id: postId.uuidString,
                message: messageText
            )
            
            let response: MessageResponse = try await client.from("messages")
                .insert(newMessage)
                .select()
                .single()
                .execute()
                .value
            
            // Fetch sender's username
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
    
    /// Create a new thread (conversation) for a post
    func createThread(postId: UUID, buyerId: UUID, sellerId: UUID) async throws -> UUID {
        do {
            print("🔄 Creating new thread for post: \(postId)")
            
            // First check if thread already exists
            struct ExistingThread: Codable {
                let id: UUID
            }
            
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
            
            // Create new thread
            struct ThreadInsert: Codable {
                let post_id: String
                let buyer_id: String
                let seller_id: String
            }
            
            struct ThreadResponse: Codable {
                let id: UUID
            }
            
            let newThread = ThreadInsert(
                post_id: postId.uuidString,
                buyer_id: buyerId.uuidString,
                seller_id: sellerId.uuidString
            )
            
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
    
    /// Subscribe to new messages in a thread (for real-time updates)
    func subscribeToMessages(threadId: UUID, onMessage: @escaping (Message) -> Void) async throws {
        // Note: Real-time subscriptions require additional setup in Supabase
        // For now, this is a placeholder that can be implemented when real-time is needed
        print("📡 Real-time message subscription would be set up here for thread: \(threadId)")
        // Implementation would use Supabase Realtime channels
    }
}
