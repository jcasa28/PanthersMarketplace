//
//  Panthers_MarketplaceApp.swift
//  Panthers Marketplace
//
//  Created by Jesus Casasanta on 10/6/25.
//

import SwiftUI

@main
struct Panthers_MarketplaceApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            AuthView()
                .environmentObject(authVM)
        }
    }
}

