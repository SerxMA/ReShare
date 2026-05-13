import Foundation
import Combine

@MainActor
final class ListingDetailViewModel: ObservableObject {
    @Published var detail: ListingDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let listingId: String

    init(listingId: String) {
        self.listingId = listingId
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            detail = try await ListingsService.shared.fetchListingDetail(listingId: listingId)
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
        }

        isLoading = false
    }
}
