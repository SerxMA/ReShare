import SwiftUI

struct MainTabView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var messagesViewModel = MessagesViewModel()
    
    var body: some View {
        TabView {
            
            // 📦 ЛЕНТА
            FeedView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Лента")
                }
            
            // ❤️ ИЗБРАННОЕ
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Избранное")
                }
            
            // ➕ МОИ ОБЪЯВЛЕНИЯ
            MyListingsView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Объявления")
                }
            
            // 💬 СООБЩЕНИЯ
            MessagesView(viewModel: messagesViewModel)
                .tabItem {
                    Image(systemName: "message")
                    Text("Сообщения")
                }
                .badge(messagesViewModel.unreadCount > 0 ? String(messagesViewModel.unreadCount) : nil)
            
            // 👤 ПРОФИЛЬ
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Профиль")
                }
        }
        .environmentObject(favoritesManager)
        .task {
            await messagesViewModel.load()
        }
    }
}
