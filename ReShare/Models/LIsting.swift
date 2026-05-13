import Foundation

struct Listing: Identifiable {
    let id: UUID
    let apiId: String?
    let title: String
    let imageName: String
    let imageUrl: URL?
    let userName: String
    let distance: String
    let timeAgo: String
    let isGift: Bool
    let isExchange: Bool
    let isRequest: Bool
    let isPickup: Bool
    let ecoKg: Int?

    init(
        id: UUID = UUID(),
        apiId: String? = nil,
        title: String,
        imageName: String,
        imageUrl: URL? = nil,
        userName: String,
        distance: String,
        timeAgo: String,
        isGift: Bool,
        isExchange: Bool,
        isRequest: Bool,
        isPickup: Bool,
        ecoKg: Int? = nil
    ) {
        self.id = id
        self.apiId = apiId
        self.title = title
        self.imageName = imageName
        self.imageUrl = imageUrl
        self.userName = userName
        self.distance = distance
        self.timeAgo = timeAgo
        self.isGift = isGift
        self.isExchange = isExchange
        self.isRequest = isRequest
        self.isPickup = isPickup
        self.ecoKg = ecoKg
    }

    init(apiItem: ListingPreviewAPIModel) {
        self.id = UUID(uuidString: apiItem.id) ?? UUID()
        self.apiId = apiItem.id
        self.title = apiItem.title
        self.imageName = "iphone"
        self.imageUrl = URL(string: apiItem.thumbnailUrl ?? "")
        self.userName = apiItem.donor?.fullName ?? "Аноним"
        self.distance = apiItem.city
        self.timeAgo = Listing.relativeDateText(from: apiItem.createdAt)

        let transferType = apiItem.transferType.lowercased()
        self.isGift = transferType.contains("donation") || transferType.contains("gift")
        self.isExchange = transferType.contains("exchange")
        self.isRequest = transferType.contains("request")
        self.isPickup = false
        self.ecoKg = apiItem.weightGrams > 0 ? Int(apiItem.weightGrams / 1000) : nil
    }

    init(favorite: FavoriteListing) {
        self.id = UUID()
        self.apiId = favorite.apiId
        self.title = favorite.title
        self.imageName = favorite.imageName
        self.imageUrl = favorite.imageUrl.flatMap(URL.init(string:))
        self.userName = favorite.userName
        self.distance = favorite.distance
        self.timeAgo = favorite.timeAgo
        self.isGift = favorite.isGift
        self.isExchange = favorite.isExchange
        self.isRequest = favorite.isRequest
        self.isPickup = favorite.isPickup
        self.ecoKg = favorite.ecoKg
    }

    init(detail: ListingDetail) {
        self.id = UUID()
        self.apiId = detail.apiId
        self.title = detail.title
        self.imageName = "iphone"
        self.imageUrl = detail.photos.first?.url
        self.userName = detail.userName
        self.distance = detail.city
        self.timeAgo = Listing.relativeDateText(from: detail.createdAt)
        self.isGift = detail.transferTypeName.lowercased().contains("gift") || detail.transferTypeName.lowercased().contains("donation")
        self.isExchange = detail.transferTypeName.lowercased().contains("exchange")
        self.isRequest = detail.transferTypeName.lowercased().contains("request")
        self.isPickup = detail.transferMethodName.lowercased().contains("person")
        self.ecoKg = detail.ecoKg
    }

    private static func relativeDateText(from isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoDate) else {
            return ""
        }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Только что"
        }
        if interval < 3600 {
            return "\(Int(interval / 60)) мин назад"
        }
        if interval < 86_400 {
            return "\(Int(interval / 3600)) ч назад"
        }
        return "\(Int(interval / 86_400)) д назад"
    }
}

struct ListingPreviewAPIModel: Decodable {
    let id: String
    let title: String
    let category: CategoryAPIModel
    let condition: String
    let transferType: String
    let status: String
    let city: String
    let thumbnailUrl: String?
    let donor: DonorAPIModel?
    let viewCount: Int
    let weightGrams: Int
    let co2SavedG: Int
    let wasteSavedG: Int
    let createdAt: String
}

struct CategoryAPIModel: Decodable {
    let id: String
    let name: String
    let parentCategoryId: String?
}

struct DonorAPIModel: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let rating: Double
    let reviewCount: Int

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

struct ListingPhotoAPIModel: Decodable {
    let id: String
    let url: String
    let displayOrder: Int
}

struct LocationAPIModel: Decodable {
    let city: String
    let district: String?
    let latitude: Double?
    let longitude: Double?
}

struct ListingDetailAPIModel: Decodable {
    let id: String
    let title: String
    let description: String
    let category: CategoryAPIModel
    let condition: String
    let transferType: String
    let transferMethod: String
    let status: String
    let location: LocationAPIModel
    let donor: DonorAPIModel?
    let photos: [ListingPhotoAPIModel]
    let tags: [String]
    let viewCount: Int
    let weightGrams: Int
    let co2SavedG: Int
    let wasteSavedG: Int
    let createdAt: String
    let updatedAt: String?
}

struct ListingPhoto: Identifiable {
    let id: String
    let url: URL
    let displayOrder: Int
}

struct ListingDetail: Identifiable {
    let id: UUID
    let apiId: String
    let title: String
    let description: String
    let categoryName: String
    let conditionName: String
    let transferTypeName: String
    let transferMethodName: String
    let status: String
    let city: String
    let district: String?
    let photos: [ListingPhoto]
    let tags: [String]
    let userName: String
    let userAvatarUrl: URL?
    let viewCount: Int
    let weightGrams: Int
    let ecoKg: Int?
    let createdAt: String

    init(apiDetail: ListingDetailAPIModel) {
        self.id = UUID(uuidString: apiDetail.id) ?? UUID()
        self.apiId = apiDetail.id
        self.title = apiDetail.title
        self.description = apiDetail.description
        self.categoryName = apiDetail.category.name
        self.conditionName = apiDetail.condition
        self.transferTypeName = apiDetail.transferType
        self.transferMethodName = apiDetail.transferMethod
        self.status = apiDetail.status
        self.city = apiDetail.location.city
        self.district = apiDetail.location.district
        self.photos = apiDetail.photos
            .sorted(by: { $0.displayOrder < $1.displayOrder })
            .compactMap { photo in
                guard let url = URL(string: photo.url) else { return nil }
                return ListingPhoto(id: photo.id, url: url, displayOrder: photo.displayOrder)
            }
        self.tags = apiDetail.tags
        self.userName = apiDetail.donor?.fullName ?? "Аноним"
        self.userAvatarUrl = URL(string: apiDetail.donor?.avatarUrl ?? "")
        self.viewCount = apiDetail.viewCount
        self.weightGrams = apiDetail.weightGrams
        self.ecoKg = apiDetail.weightGrams > 0 ? Int(apiDetail.weightGrams / 1000) : nil
        self.createdAt = apiDetail.createdAt
    }
}
