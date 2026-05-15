import Foundation
import Combine

@MainActor
final class ListingDetailViewModel: ObservableObject {
    @Published var detail: ListingDetail?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let listingId: String

    init(listingId: String) {
        self.listingId = listingId
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        print("🔍 ListingDetailViewModel: Загружаем объявление с id: \(listingId)")

        do {
            detail = try await ListingsService.shared.fetchListingDetail(listingId: listingId)
            print("✅ ListingDetailViewModel: Объявление загружено: \(detail?.title ?? "без названия")")
        } catch {
            print("❌ ListingDetailViewModel: Ошибка загрузки: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            detail = nil
        }

        isLoading = false
    }
}
