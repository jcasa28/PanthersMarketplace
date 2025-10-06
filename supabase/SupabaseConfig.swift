import Foundation

enum SupabaseConfig {
    static let projectRef = Environment.value(for: "SUPABASE_PROJECT_REF")
    static let baseURL = URL(string: Environment.value(for: "SUPABASE_URL"))!
    static let anonKey = Environment.value(for: "SUPABASE_ANON_KEY")
    
    static var authURL: URL { baseURL.appending(path: "auth/v1") }
    static var restURL: URL { baseURL.appending(path: "rest/v1") }
    static var functionsURL: URL { baseURL.appending(path: "functions/v1") }
}
