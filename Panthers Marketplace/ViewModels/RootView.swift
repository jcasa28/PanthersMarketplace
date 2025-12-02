import SwiftUI

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var chatVM: ChatViewModel

    init() {
        // Initialize ChatViewModel with AuthViewModel reference (like ListingsViewModel does)
        let auth = AuthViewModel()
        _authVM = StateObject(wrappedValue: auth)
        _chatVM = StateObject(wrappedValue: ChatViewModel(authVM: auth))
    }

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                ContentView()
                    .environmentObject(authVM)
                    .environmentObject(chatVM)
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
