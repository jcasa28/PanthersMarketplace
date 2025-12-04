// In ProfileView.swift, in the toolbar logout button action
Button(role: .destructive) {
    Task {
        await authVM.signOut()
        // Clear ProfileViewModel state after sign out
        await MainActor.run {
            profileVM.resetForLogout()
        }
    }
} label: {
    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
}
