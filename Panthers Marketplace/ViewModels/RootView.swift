import SwiftUI

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                ContentView()
                    .environmentObject(authVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
        .animation(.default, value: authVM.isLoggedIn)
    }
}

#Preview {
    RootView()
}
