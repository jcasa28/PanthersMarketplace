//
//  SignUpView.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//


import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Create your account")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign up with your @fiu.edu email to use Panthers Marketplace.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Fields
                VStack(spacing: 16) {
                    TextField("Full name", text: $fullName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    TextField("FIU email (@fiu.edu)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    SecureField("Password (min 8 characters)", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    SecureField("Confirm password", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                // Error
                if let error = authVM.errorMessage, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign Up button
                Button(action: signUp) {
                    if authVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 7/255, green: 32/255, blue: 64/255)) // FIU-ish blue
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(isButtonDisabled)

                // Already have account
                Button {
                    dismiss()
                } label: {
                    Text("Already have an account? Log in")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: authVM.isLoggedIn) { _, loggedIn in
                if loggedIn {
                    dismiss()
                }
            }
        }
    }

    private var isButtonDisabled: Bool {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        authVM.isLoading
    }

    private func signUp() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedEmail.lowercased().hasSuffix("@fiu.edu") else {
            authVM.errorMessage = "Please use your @fiu.edu email."
            return
        }

        guard trimmedPassword.count >= 8 else {
            authVM.errorMessage = "Password must be at least 8 characters."
            return
        }

        guard trimmedPassword == trimmedConfirm else {
            authVM.errorMessage = "Passwords do not match."
            return
        }

        Task {
            await authVM.signUp(
                fullName: trimmedName,
                email: trimmedEmail,
                password: trimmedPassword
            )
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
