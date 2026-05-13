import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""

    func loadListings() async {
        isLoading = true
        errorMessage = nil

        do {
            listings = try await ListingsService.shared.fetchListings(searchQuery: searchText)
        } catch {
            errorMessage = error.localizedDescription
            listings = []
        }

        isLoading = false
    }

    func refresh() {
        Task {
            await loadListings()
        }
    }
}
