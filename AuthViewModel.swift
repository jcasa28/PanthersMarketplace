// In AuthViewModel.swift

/// Sign out
func signOut() async {
    await runAuthOperation {
        try await self.client.auth.signOut()
        
        // Clear network caches that may contain signed avatar images
        AuthViewModel.clearWebCaches()
        
        // Clear our session state
        self.clearSession()
    }
}

/// Clears URLCache, HTTP cookies, and cached responses (called on logout)
static func clearWebCaches() {
    // Clear URLCache (memory + disk)
    let cache = URLCache.shared
    cache.removeAllCachedResponses()
    cache.memoryCapacity = 0
    cache.diskCapacity = 0
    
    // Clear cookies
    HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    
    // Clear cached URL responses for current session if any custom sessions exist (most use shared)
    // If you have custom URLSessions, clear their caches too.
}
