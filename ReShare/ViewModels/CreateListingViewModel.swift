import Foundation
import _PhotosUI_SwiftUI
import Combine
import UIKit
import PhotosUI

enum ListingCondition: String, CaseIterable, Identifiable, Codable {
    case New = "New"
    case LikeNew = "LikeNew"
    case Good = "Good"
    case Fair = "Fair"
    case Poor = "Poor"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .New: return "Новое"
        case .LikeNew: return "Как новое"
        case .Good: return "Хорошее"
        case .Fair: return "Среднее"
        case .Poor: return "Плохое"
        }
    }
}

enum ListingTransferType: String, CaseIterable, Identifiable {
    case Gift = "Gift"
    case Exchange = "Exchange"
    case Charity = "Charity"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .Gift: return "Дарение"
        case .Exchange: return "Обмен"
        case .Charity: return "Благотворительность"
        }
    }
}

enum ListingTransferMethod: String, CaseIterable, Identifiable {
    case InPerson = "InPerson"
    case Delivery = "Delivery"
    case Both = "Both"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .InPerson: return "Самовывоз"
        case .Delivery: return "Доставка"
        case .Both: return "Оба"
        }
    }
}

@MainActor
final class CreateListingViewModel: ObservableObject {
    let editingListingId: String?
    let existingCategoryName: String?

    @Published var title: String = ""
    @Published var description: String = ""
    @Published var city: String = ""
    @Published var weight: String = ""
    @Published var tagsText: String = ""
    @Published var condition: ListingCondition = .Good
    @Published var transferType: ListingTransferType = .Gift
    @Published var transferMethod: ListingTransferMethod = .InPerson
    @Published var categories: [CategoryAPIModel] = []
    @Published var selectedCategoryId: String?
    @Published var selectedImages: [UIImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    var isEditing: Bool {
        editingListingId != nil
    }

    var hasPhotos: Bool {
        isEditing || !selectedImages.isEmpty
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Int(weight) != nil
            && selectedCategoryId != nil
            && hasPhotos
    }

    init(existingDetail: ListingDetail? = nil) {
        self.editingListingId = existingDetail?.apiId
        self.existingCategoryName = existingDetail?.categoryName

        if let detail = existingDetail {
            title = detail.title
            description = detail.description
            city = detail.city
            weight = String(detail.weightGrams)
            tagsText = detail.tags.joined(separator: ", ")
            condition = ListingCondition(rawValue: detail.conditionName) ?? .Good
            transferType = ListingTransferType(rawValue: detail.transferTypeName) ?? .Gift
            transferMethod = ListingTransferMethod(rawValue: detail.transferMethodName) ?? .InPerson
        }
    }

    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        do {
            categories = try await ListingsService.shared.fetchCategories()
            if let existingCategoryName = existingCategoryName,
               let matchedCategory = categories.first(where: { $0.name == existingCategoryName }) {
                selectedCategoryId = matchedCategory.id
            } else {
                selectedCategoryId = categories.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateSelectedPhotos(from items: [PhotosPickerItem]) async {
        selectedImages = []
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImages.append(image)
                }
            } catch {
                // Игнорируем неудачные элементы, оставляем остальные
            }
        }
    }

    func saveListing() async throws {
        guard let categoryId = selectedCategoryId else {
            throw NSError(domain: "CreateListingViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Выберите категорию"]) 
        }
        guard let weightGrams = Int(weight) else {
            throw NSError(domain: "CreateListingViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Введите корректный вес"])
        }
        guard hasPhotos else {
            throw NSError(domain: "CreateListingViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Добавьте хотя бы одну фотографию"])
        }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let request = CreateListingRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            categoryId: categoryId,
            weightGrams: weightGrams,
            condition: condition.rawValue,
            transferType: transferType.rawValue,
            transferMethod: transferMethod.rawValue,
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            district: nil,
            latitude: nil,
            longitude: nil,
            tags: tags.isEmpty ? nil : tags
        )

        isLoading = true
        errorMessage = nil
        do {
            if let listingId = editingListingId {
                try await ListingsService.shared.updateListing(listingId, request: request)

                if !selectedImages.isEmpty {
                    for (index, image) in selectedImages.enumerated() {
                        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                            continue
                        }
                        let uploadedUrl = try await ListingsService.shared.uploadFile(imageData, fileName: "listing-photo-\(index + 1).jpg")
                        try await ListingsService.shared.addListingPhoto(listingId: listingId, photoUrl: uploadedUrl, displayOrder: index)
                    }
                }

                successMessage = "Объявление успешно обновлено"
            } else {
                let listingId = try await ListingsService.shared.createListing(request)

                var uploadedPhotoUrls: [String] = []
                for (index, image) in selectedImages.enumerated() {
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        continue
                    }
                    let uploadedUrl = try await ListingsService.shared.uploadFile(imageData, fileName: "listing-photo-\(index + 1).jpg")
                    try await ListingsService.shared.addListingPhoto(listingId: listingId, photoUrl: uploadedUrl, displayOrder: index)
                    uploadedPhotoUrls.append(uploadedUrl)
                }

                if !uploadedPhotoUrls.isEmpty {
                    try await ListingsService.shared.updateListingStatus(listingId: listingId, status: "Active")
                }

                successMessage = "Объявление успешно создано"
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        isLoading = false
    }
}
