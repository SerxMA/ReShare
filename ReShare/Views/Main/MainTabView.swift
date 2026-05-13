import SwiftUI

struct MainTabView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    
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
            MessagesView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Сообщения")
                }
            
            // 👤 ПРОФИЛЬ
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Профиль")
                }
        }
        .environmentObject(favoritesManager)
    }
}
