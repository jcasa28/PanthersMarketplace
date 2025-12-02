import SwiftUI

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                ContentView()
                    .environmentObject(authVM)
                    .environmentObject(profileVM)
                    
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
