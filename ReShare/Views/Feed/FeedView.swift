import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var locationService = LocationService()
    @EnvironmentObject private var favoritesManager: FavoritesManager

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
                        text: $viewModel.searchText,
                        placeholder: "Поиск",
                        leftIcon: Image(systemName: "magnifyingglass"),
                        rightIcon: Image(systemName: "slider.horizontal.3"),
                        inputStyle: .shaded
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)

                Divider()

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.03))
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text("Не удалось загрузить объявления")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Повторить") {
                            viewModel.refresh()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.03))
                } else if viewModel.listings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Объявлений пока нет")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Попробуйте изменить фильтры или зайдите позже — новые объявления появляются каждый день.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Button("Обновить") {
                            viewModel.refresh()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.03))
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.listings) { listing in
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
            .task {
                await viewModel.loadListings()
                locationService.requestLocation()
            }
        }
    }
}
