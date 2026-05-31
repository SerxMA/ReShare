import Foundation
import Combine

struct FavoriteListing: Codable, Identifiable, Equatable {
    let id: String
    let apiId: String
    let title: String
    let imageName: String
    let imageUrl: String?
    let userName: String
    let distance: String
    let timeAgo: String
    let isGift: Bool
    let isExchange: Bool
    let isRequest: Bool
    let isPickup: Bool
    let ecoKg: Int?
    let categoryId: String?
    let categoryName: String
    let conditionName: String
    let condition: ListingCondition?

    init(listing: Listing) {
        self.id = listing.apiId ?? UUID().uuidString
        self.apiId = listing.apiId ?? UUID().uuidString
        self.title = listing.title
        self.imageName = listing.imageName
        self.imageUrl = listing.imageUrl?.absoluteString
        self.userName = listing.userName
        self.distance = listing.distance
        self.timeAgo = listing.timeAgo
        self.isGift = listing.isGift
        self.isExchange = listing.isExchange
        self.isRequest = listing.isRequest
        self.isPickup = listing.isPickup
        self.ecoKg = listing.ecoKg
        self.categoryId = listing.categoryId
        self.categoryName = listing.categoryName
        self.conditionName = listing.conditionName
        self.condition = listing.condition
    }
}

@MainActor
final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published private(set) var favoriteListings: [FavoriteListing] = []

    private let storageKey = "favoriteListings"

    private init() {
        loadFavorites()
    }

    func isFavorite(listingId: String?) -> Bool {
        guard let listingId else { return false }
        return favoriteListings.contains { $0.apiId == listingId }
    }

    func toggleFavorite(listing: Listing) {
        guard let apiId = listing.apiId else { return }
        if isFavorite(listingId: apiId) {
            removeFavorite(apiId: apiId)
        } else {
            addFavorite(listing: listing)
        }
    }

    func addFavorite(listing: Listing) {
        guard let apiId = listing.apiId else { return }
        guard !favoriteListings.contains(where: { $0.apiId == apiId }) else { return }
        let favorite = FavoriteListing(listing: listing)
        favoriteListings.append(favorite)
        saveFavorites()
    }

    func removeFavorite(apiId: String) {
        favoriteListings.removeAll { $0.apiId == apiId }
        saveFavorites()
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            favoriteListings = try JSONDecoder().decode([FavoriteListing].self, from: data)
        } catch {
            favoriteListings = []
        }
    }

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favoriteListings)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // ignore save error
        }
    }
}
