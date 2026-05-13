import SwiftUI

@main
struct ReShareApp: App {
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    init() {
        if !isAuthenticated, TokenStorage.shared.readToken() != nil {
            isAuthenticated = true
        }
    }

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}
