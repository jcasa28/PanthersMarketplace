import SwiftUI

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()

    @StateObject private var profileVM = ProfileViewModel()
    

    @StateObject private var chatVM: ChatViewModel

    init() {
        // Initialize ChatViewModel with AuthViewModel reference (like ListingsViewModel does)
        let auth = AuthViewModel()
        _authVM = StateObject(wrappedValue: auth)
        _chatVM = StateObject(wrappedValue: ChatViewModel(authVM: auth))
        _profileVM = StateObject(wrappedValue: ProfileViewModel())
    }


    var body: some View {
        Group {
            if authVM.isLoggedIn {
                ContentView()
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
