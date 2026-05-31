import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    let isFavorite: Bool
    let onFavoriteToggle: (() -> Void)?
    
    init(listing: Listing, isFavorite: Bool = false, onFavoriteToggle: (() -> Void)? = nil) {
        self.listing = listing
        self.isFavorite = isFavorite
        self.onFavoriteToggle = onFavoriteToggle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 🖼 КАРТИНКА
            ZStack(alignment: .top) {
                if let imageUrl = listing.imageUrl {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            Color(.systemGray5)
                                .overlay(ProgressView())
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        case .failure:
                            Image(listing.imageName)
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        @unknown default:
                            Color(.systemGray5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                } else {
                    Image(listing.imageName)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }

                VStack {
                    HStack(alignment: .top) {
                        // 📌 статусы слева сверху
                        VStack(alignment: .leading, spacing: 6) {
                            if listing.isGift {
                                TagView("Дарение", color: .green, size: .small, style: .filled)
                            }

                            if listing.isExchange {
                                TagView("Обмен", color: .blue, size: .small, style: .filled)
                            }

                            if listing.isRequest {
                                TagView("Запрос", color: .orange, size: .small, style: .filled)
                            }
                        }

                        Spacer()

                        // ❤️ избранное
                        Button(action: {
                            onFavoriteToggle?()
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .primary)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
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
            .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
            .background(Color(.systemGray5))
            .clipped()
            .cornerRadius(16)

            // 📌 НАЗВАНИЕ
            Text(listing.title)
                .font(.headline)

            // 👤 АВТОР
            HStack(spacing: 8) {
                AvatarView(imageName: "person.crop.circle.fill", systemImage: true, size: .small, shape: .circle, statusDot: false)

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
        .frame(maxWidth: 380)
    }
}
