import SwiftUI

struct MessagesView: View {
    @State private var searchText: String = ""
    
    let listings: [Listing] = [
        Listing(
            title: "iPhone 13 Pro",
            imageName: "iphone",
            userName: "Alex",
            distance: "2 км",
            timeAgo: "1 ч назад",
            isGift: false,
            isExchange: false,
            isRequest: false,
            isPickup: true,
            ecoKg: 12
        ),
        
        Listing(
            title: "Диван IKEA",
            imageName: "sofa",
            userName: "Maria",
            distance: "5 км",
            timeAgo: "3 ч назад",
            isGift: true,
            isExchange: false,
            isRequest: false,
            isPickup: true,
            ecoKg: nil
        ),
        
        Listing(
            title: "MacBook Air M1",
            imageName: "laptop",
            userName: "Ivan",
            distance: "1 км",
            timeAgo: "10 мин назад",
            isGift: false,
            isExchange: true,
            isRequest: false,
            isPickup: false,
            ecoKg: 5
        )
    ]
    
    var body: some View {
        NavigationView {
            
            VStack(spacing: 0) {
                
                // 📍 HEADER
                VStack(spacing: 12) {
                    
                    // Геопозиция + фильтр + поиск
                    HStack {
                        
                        // 📍 гео
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text("Amsterdam")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 🔍 поиск
                    InputBase(
                        text: $searchText,
                        placeholder: "Поиск",
                        leftIcon: Image(systemName: "magnifyingglass"),
                        rightIcon: Image(systemName: "slider.horizontal.3"),
                        inputStyle: .shaded
                    )
                    .padding(.horizontal)
                    
                }
                .padding(.bottom, 10)
                
                // ➖ разделитель
                Divider()
                
                // 📦 ЛЕНТА
                ScrollView {
                    
                    VStack(spacing: 12) {
                        
                        ForEach(listings) { listing in
                            ListingCardView(listing: listing)
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal)
                }
                .background(Color.black.opacity(0.03)) // 🎨 фон ленты
            }
            .navigationBarHidden(true)
        }
    }
}
