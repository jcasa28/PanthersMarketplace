import SwiftUI

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var chatVM: ChatViewModel

    init() {
        // Use the same AuthViewModel instance for both environment and ChatViewModel
        let sharedAuth = AuthViewModel()
        _authVM = StateObject(wrappedValue: sharedAuth)
        _profileVM = StateObject(wrappedValue: ProfileViewModel())
        _chatVM = StateObject(wrappedValue: ChatViewModel(authVM: sharedAuth))
    }

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                FeedView()
                    .environmentObject(authVM)
                    .environmentObject(profileVM)
                    .environmentObject(chatVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
                    .environmentObject(profileVM)
            }
        }
        .animation(.default, value: authVM.isLoggedIn)
    }
}

#Preview {
    RootView()
}
