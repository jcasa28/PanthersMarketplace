//
//  AuthViewModel.swift
//  Panthers Marketplace
//
//  Created by Eilyn Fabiana Tudares Granadillo on 11/12/25.



import Foundation
import Supabase
#if canImport(GoTrue)
import GoTrue
#endif

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published state used by the UI

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var session: Session?
    @Published var userId: UUID?
    @Published var email: String?

    // Profile-ish data used by ProfileView
    @Published var displayName: String?
    @Published var photoURL: URL?
    @Published var rating: Double?

    // MARK: - Supabase client

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Convenience

    /// User is considered logged in only if we have a non-nil, non-expired session
    var isLoggedIn: Bool {
        if let session = session {
            return !session.isExpired
        }
        return false
    }

    // MARK: - Init

    init() {
        // For now, DO NOT auto-restore session on launch.
        // This ensures the app always starts on LoginView.
        //
        // If later you want auto-login, you can uncomment:
        //
        // Task {
        //     await restoreSession()
        // }
    }

    // MARK: - Public API
    /// Email + password sign up (with full name metadata)
    func signUp(fullName: String, email: String, password: String) async {
        guard isFIU(email) else {
            errorMessage = "Use your @fiu.edu email."
            return
        }

        await runAuthOperation {

            // Send profile metadata to Supabase
            let metadata: [String: AnyJSON] = [
                "full_name": .string(fullName)
            ]

            _ = try await self.client.auth.signUp(
                email: email,
                password: password,
                data: metadata
            )

            // After signup, fetch the current session from Supabase
            await self.restoreSession()
        }
    }

    /// Email + password sign in
    func signIn(email: String, password: String) async {
        guard isFIU(email) else {
            errorMessage = "Use your @fiu.edu email."
            return
        }

        await runAuthOperation {
            _ = try await self.client.auth.signIn(
                email: email,
                password: password
            )

            await self.restoreSession()
        }
    }

    /// Sign out
    func signOut() async {
        await runAuthOperation {
            try await self.client.auth.signOut()
            self.clearSession()
        }
    }

    /// Refresh (re-fetch) current session from Supabase.
    /// You can call this manually later if you want "remember me" behavior.
    func restoreSession() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentSession = try await client.auth.session

            if currentSession.isExpired {
                clearSession()
            } else {
                await applySession(currentSession)
            }
        } catch {
            clearSession()
            errorMessage = friendlyError(error)
        }

        isLoading = false
    }

    // MARK: - Private helpers

    /// Wraps auth operations with common loading/error handling
    private func runAuthOperation(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil

        do {
            try await operation()
        } catch {
            errorMessage = friendlyError(error)
        }

        isLoading = false
    }

    /// Apply a Supabase `Session` to our published state
    private func applySession(_ session: Session) async {
        self.session = session
        self.userId = session.user.id
        self.email = session.user.email

        // You can later replace this with a profile fetch
        self.displayName = session.user.email
        self.rating = nil
        self.photoURL = nil
    }

    /// Clear all user-related state
    private func clearSession() {
        session = nil
        userId = nil
        email = nil
        displayName = nil
        photoURL = nil
        rating = nil
    }

    /// Simple FIU email validation
    private func isFIU(_ email: String) -> Bool {
        email.lowercased().hasSuffix("@fiu.edu")
    }

    /// Convert Swift / Supabase errors into friendly messages
    private func friendlyError(_ error: Error) -> String {
        if let postgrestError = error as? PostgrestError {
            return postgrestError.message
        }
        return error.localizedDescription
    }
}
