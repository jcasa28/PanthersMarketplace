//
//  AuthView.swift
//  Panthers Marketplace
//
//  Created by Eilyn Fabiana Tudares Granadillo on 11/12/25.
//


import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                // 🔹 Main/home screen after login
                FeedView()
            } else {
                // 🔹 First screen when NOT logged in
                LoginView()
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
