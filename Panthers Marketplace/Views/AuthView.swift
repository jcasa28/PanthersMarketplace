//
//  AuthView.swift (This is a placeholder)
//  Panthers Marketplace
//
//  Created by Eilyn Fabiana Tudares Granadillo on 11/12/25.
//



import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            if authVM.isLoggedIn {
                Text("You are logged in as:")
                    .font(.headline)

                if let email = authVM.email {
                    Text(email)
                        .font(.subheadline)
                }

                Button("Sign Out") {
                    Task {
                        await authVM.signOut()
                    }
                }
                .buttonStyle(.borderedProminent)

            } else {
                Text("Not logged in")
                    .font(.headline)
                Text("Use LoginView to sign in with your @fiu.edu email.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
