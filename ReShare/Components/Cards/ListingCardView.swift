import SwiftUI

struct ListingCardView: View {
    
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 🖼 КАРТИНКА
            ZStack(alignment: .top) {
                
                Image(listing.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(16)
                
                // 🎯 OVERLAYS НА КАРТИНКЕ
                VStack {
                    
                    HStack(alignment: .top) {
                        
                        // 📌 статусы слева сверху
                        VStack(alignment: .leading, spacing: 6) {
                            
                            if listing.isGift {
                                statusTag("Дарение", color: .green)
                            }
                            
                            if listing.isExchange {
                                statusTag("Обмен", color: .blue)
                            }
                            
                            if listing.isRequest {
                                statusTag("Запрос", color: .orange)
                            }
                        }
                        
                        Spacer()
                        
                        // ❤️ лайк справа сверху
                        Image(systemName: "heart")
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .padding(10)
                    
                    Spacer()
                    
                    // 📦 нижняя часть картинки
                    HStack {
                        
                        if listing.isPickup {
                            HStack(spacing: 6) {
                                Image(systemName: "car.fill")
                                Text("Самовывоз")
                            }
                            .font(.caption)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                        }
                        
                        if let eco = listing.ecoKg {
                            HStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                Text("\(eco) кг")
                            }
                            .font(.caption)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(10)
                }
            }
            
            // 📌 НАЗВАНИЕ
            Text(listing.title)
                .font(.headline)
            
            // 👤 АВТОР
            HStack(spacing: 8) {
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                
                Text(listing.userName)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            // 📍 НИЗ КАРТОЧКИ
            HStack {
                
                Text(listing.distance)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(listing.timeAgo)
                    .foregroundColor(.gray)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.white) // 🤍 карточка белая
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // 🔧 helper для статусов
    private func statusTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .cornerRadius(8)
    }
}
