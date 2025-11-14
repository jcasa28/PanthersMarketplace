//
//  LoginView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//


//
//  LoginView.swift
//  Panthers Marketplace
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss  

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Panthers Marketplace")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign in with your @fiu.edu email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                VStack(spacing: 16) {
                    TextField("FIU email (@fiu.edu)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                if let error = authVM.errorMessage, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: login) {
                    if authVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 7/255, green: 32/255, blue: 64/255))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("Log In")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: authVM.isLoggedIn) { _, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }

    private func login() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else { return }

        Task {
            await authVM.signIn(email: trimmedEmail, password: trimmedPassword)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
