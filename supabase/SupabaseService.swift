import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = Environment.value(for: "SUPABASE_URL")
        let supabaseKey = Environment.value(for: "SUPABASE_ANON_KEY")
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
    }
    
    // Test function to verify database connection
    func testConnection() async throws -> Bool {
        do {
            // Simple query to check if we can connect to the database
            let response = try await client.database
                .from("posts")
                .select()
                .limit(1)
                .execute()
            
            print("Successfully connected to Supabase!")
            return true
        } catch {
            print("Failed to connect to Supabase: \(error)")
            return false
        }
    }
}
