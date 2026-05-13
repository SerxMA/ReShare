import Foundation
import Combine

@MainActor
final class MyListingsViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadMyListings() async {
        isLoading = true
        errorMessage = nil

        do {
            listings = try await ListingsService.shared.fetchMyListings()
        } catch {
            errorMessage = error.localizedDescription
            listings = []
        }

        isLoading = false
    }

    func refresh() {
        Task {
            await loadMyListings()
        }
    }
}
