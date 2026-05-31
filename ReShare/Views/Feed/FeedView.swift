import SwiftUI

private enum FeedFilter: String, CaseIterable, Identifiable {
    case gift = "Дарение"
    case exchange = "Обмен"
    case request = "Запрос"

    var id: String { rawValue }
}

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var locationService = LocationService()
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var isShowingFilterSheet = false
    @State private var selectedTransferTypes: Set<FeedFilter> = []
    @State private var selectedConditions: Set<ListingCondition> = []
    @State private var selectedCategoryIds: Set<String> = []
    @State private var categories: [CategoryAPIModel] = []

    private var filteredListings: [Listing] {
        viewModel.listings.filter { listing in
            if !selectedTransferTypes.isEmpty {
                let matchesType = (selectedTransferTypes.contains(.gift) && listing.isGift)
                    || (selectedTransferTypes.contains(.exchange) && listing.isExchange)
                    || (selectedTransferTypes.contains(.request) && listing.isRequest)
                if !matchesType {
                    return false
                }
            }

            if !selectedConditions.isEmpty {
                guard let condition = listing.condition else {
                    return false
                }
                if !selectedConditions.contains(condition) {
                    return false
                }
            }

            if !selectedCategoryIds.isEmpty {
                guard let categoryId = listing.categoryId else {
                    return false
                }
                if !selectedCategoryIds.contains(categoryId) {
                    return false
                }
            }

            return true
        }
    }

    private func loadCategories() async {
        do {
            categories = try await ListingsService.shared.fetchCategories()
        } catch {
            print("Не удалось загрузить категории для фильтров: \(error)")
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
                        text: $viewModel.searchText,
                        placeholder: "Поиск",
                        leftIcon: Image(systemName: "magnifyingglass"),
                        rightIcon: Image(systemName: "slider.horizontal.3"),
                        rightIconAction: {
                            isShowingFilterSheet = true
                        },
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
                            ForEach(filteredListings) { listing in
                                HStack {
                                    Spacer(minLength: 0)
                                    if let apiId = listing.apiId {
                                        NavigationLink(destination: ListingDetailView(listingId: apiId)) {
                                            ListingCardView(
                                                listing: listing,
                                                isFavorite: favoritesManager.isFavorite(listingId: apiId),
                                                onFavoriteToggle: {
                                                    favoritesManager.toggleFavorite(listing: listing)
                                                }
                                            )
                                            .frame(maxWidth: 380)
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
                                        .frame(maxWidth: 380)
                                    }
                                    Spacer(minLength: 0)
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
                await loadCategories()
            }
            .sheet(isPresented: $isShowingFilterSheet) {
                FilterSheet(
                    selectedTransferTypes: $selectedTransferTypes,
                    selectedConditions: $selectedConditions,
                    selectedCategoryIds: $selectedCategoryIds,
                    categories: categories,
                    isPresented: $isShowingFilterSheet
                )
            }
        }
    }
}

private struct FilterSheet: View {
    @Binding var selectedTransferTypes: Set<FeedFilter>
    @Binding var selectedConditions: Set<ListingCondition>
    @Binding var selectedCategoryIds: Set<String>
    let categories: [CategoryAPIModel]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Фильтры")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Тип объявления")
                        .foregroundColor(.secondary)

                    ForEach(FeedFilter.allCases) { filter in
                        filterButton(title: filter.rawValue, isSelected: selectedTransferTypes.contains(filter)) {
                            toggleFilter(filter)
                        }
                    }

                    Text("Состояние вещи")
                        .foregroundColor(.secondary)

                    ForEach(ListingCondition.allCases) { condition in
                        filterButton(title: condition.displayName, isSelected: selectedConditions.contains(condition)) {
                            toggleCondition(condition)
                        }
                    }

                    Text("Категория")
                        .foregroundColor(.secondary)

                    if categories.isEmpty {
                        Text("Категории загружаются...")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(categories, id: \ .id) { category in
                            filterButton(title: category.localizedName, isSelected: selectedCategoryIds.contains(category.id)) {
                                toggleCategory(category.id)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Применить") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func toggleFilter(_ filter: FeedFilter) {
        if selectedTransferTypes.contains(filter) {
            selectedTransferTypes.remove(filter)
        } else {
            selectedTransferTypes.insert(filter)
        }
    }

    private func toggleCondition(_ condition: ListingCondition) {
        if selectedConditions.contains(condition) {
            selectedConditions.remove(condition)
        } else {
            selectedConditions.insert(condition)
        }
    }

    private func toggleCategory(_ categoryId: String) {
        if selectedCategoryIds.contains(categoryId) {
            selectedCategoryIds.remove(categoryId)
        } else {
            selectedCategoryIds.insert(categoryId)
        }
    }
}
