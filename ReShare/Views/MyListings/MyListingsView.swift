import SwiftUI

struct MyListingsView: View {
    @StateObject private var viewModel = MyListingsViewModel()
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var isShowingCreateSheet = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
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

                content
            }
            .navigationTitle("Мои объявления")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingCreateSheet = true }) {
                        Label("Создать", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                CreateListingView {
                    viewModel.refresh()
                }
            }
            .task {
                await viewModel.loadMyListings()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.03))
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 12) {
                Text("Не удалось загрузить ваши объявления")
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
                    .font(.system(size: 46))
                    .foregroundColor(.secondary)
                Text("Пока нет объявлений")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Создайте первое объявление, чтобы его увидели пользователи.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                ButtonBase(action: { isShowingCreateSheet = true }, color: .brand) {
                    Text("Создать объявление")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
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
}
