import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient
    
    private init() {
        let contents: String
        
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            fatalError("❌ Missing .env file in bundle")
        }
        
        do {
            contents = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            fatalError("❌ Failed to read .env file: \(error.localizedDescription)")
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
        print("✅ Initialized Supabase client with configuration from .env file")
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
}
