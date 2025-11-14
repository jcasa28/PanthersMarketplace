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

    var isLoggedIn: Bool {
        session != nil
    }

    // MARK: - Init

    init() {
        // Try to restore an existing session on app launch
        Task {
            await restoreSession()
        }
    }

    // MARK: - Public API

    /// Email + password sign up
    func signUp(email: String, password: String) async {
        guard isFIU(email) else {
            errorMessage = "Use your @fiu.edu email."
            return
        }

        await runAuthOperation {
          
            _ = try await self.client.auth.signUp(
                email: email,
                password: password
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
            // Ignore return type; just perform the auth call
            _ = try await self.client.auth.signIn(
                email: email,
                password: password
            )

            // Then fetch the session
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

    /// Refresh (re-fetch) current session from Supabase
    func restoreSession() async {
        isLoading = true
        errorMessage = nil

        do {
            // SDK exposes current session via `client.auth.session`
            if let currentSession = try? await client.auth.session {
                await applySession(currentSession)
            } else {
                clearSession()
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
