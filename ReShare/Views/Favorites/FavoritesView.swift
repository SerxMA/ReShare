import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @StateObject private var locationService = LocationService()
    @State private var searchText: String = ""

    private var listings: [Listing] {
        let converted = favoritesManager.favoriteListings.map(Listing.init(favorite:))
        if searchText.isEmpty {
            return converted
        }
        return converted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.userName.localizedCaseInsensitiveContains(searchText)
                || $0.distance.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(locationService.locationText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

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

                Divider()

                if listings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Нет избранных объявлений")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Добавьте объявления в избранное, чтобы они отображались здесь.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.03))
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(listings) { listing in
                                if let apiId = listing.apiId {
                                    NavigationLink(destination: ListingDetailView(listingId: apiId)) {
                                        ListingCardView(
                                            listing: listing,
                                            isFavorite: favoritesManager.isFavorite(listingId: apiId),
                                            onFavoriteToggle: {
                                                favoritesManager.toggleFavorite(listing: listing)
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    ListingCardView(
                                        listing: listing,
                                        isFavorite: favoritesManager.isFavorite(listingId: listing.apiId),
                                        onFavoriteToggle: {
                                            favoritesManager.toggleFavorite(listing: listing)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.top)
                        .padding(.horizontal)
                    }
                    .background(Color.black.opacity(0.03))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                locationService.requestLocation()
            }
        }
    }
}
