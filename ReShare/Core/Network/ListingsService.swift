import Foundation

struct ListingsPageResponse: Decodable {
    let items: [ListingPreviewAPIModel]
    let totalCount: Int
    let pageNumber: Int
    let pageSize: Int
    let totalPages: Int
    let hasPreviousPage: Bool
    let hasNextPage: Bool
}

struct CreateListingResponse: Decodable {
    let id: String
}

struct AddPhotoRequest: Encodable {
    let url: String
    let displayOrder: Int
}

struct ChangeStatusRequest: Encodable {
    let status: String
}

struct FileUploadResponse: Decodable {
    let id: String
    let originalName: String
    let storageKey: String
    let url: String
    let contentType: String
    let sizeBytes: Int
    let uploadedBy: String
    let createdAt: String
}

final class ListingsService {
    static let shared = ListingsService()
    private init() {}

    func fetchListings(searchQuery: String? = nil, pageNumber: Int = 1, pageSize: Int = 20) async throws -> [Listing] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pageNumber", value: String(pageNumber)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]

        if let searchQuery, !searchQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "searchQuery", value: searchQuery))
        }

        print("🔍 ListingsService: Запрашиваем ленту объявлений /listings, page=\(pageNumber), size=\(pageSize), search=\(searchQuery ?? "")")
        let response: ListingsPageResponse = try await NetworkClient.shared.request(path: "/listings", queryItems: queryItems)
        print("✅ ListingsService: Получено объявлений: \(response.items.count)")
        return response.items.map(Listing.init(apiItem:))
    }

    func fetchMyListings(searchQuery: String? = nil, pageNumber: Int = 1, pageSize: Int = 20) async throws -> [Listing] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pageNumber", value: String(pageNumber)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]

        if let searchQuery, !searchQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "searchQuery", value: searchQuery))
        }

        print("🔍 ListingsService: Запрашиваем мои объявления /listings/my, page=\(pageNumber), size=\(pageSize), search=\(searchQuery ?? "")")
        let response: ListingsPageResponse = try await NetworkClient.shared.request(path: "/listings/my", queryItems: queryItems)
        print("✅ ListingsService: Получено моих объявлений: \(response.items.count)")
        return response.items.map(Listing.init(apiItem:))
    }

    func fetchCategories() async throws -> [CategoryAPIModel] {
        print("🔍 ListingsService: Загружаем категории")
        let categories: [CategoryAPIModel] = try await NetworkClient.shared.request(path: "/categories")
        print("✅ ListingsService: Загружено категорий: \(categories.count)")
        return categories
    }

    func createListing(_ request: CreateListingRequest) async throws -> String {
        let body = try JSONEncoder().encode(request)
        print("🔍 ListingsService: Создаём объявление")
        let (data, response) = try await NetworkClient.shared.requestWithResponse(path: "/listings", method: .post, body: body)
        if data.isEmpty {
            if let location = response.value(forHTTPHeaderField: "Location"), let id = location.split(separator: "/").last {
                let listingId = String(id)
                print("✅ ListingsService: Объявление создано по Location: \(listingId)")
                return listingId
            }
            throw NetworkError.emptyData
        }

        if let parsedResponse = try? JSONDecoder().decode(CreateListingResponse.self, from: data) {
            print("✅ ListingsService: Объявление создано: \(parsedResponse.id)")
            return parsedResponse.id
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let id = json["id"] as? String {
            print("✅ ListingsService: Объявление создано (json id): \(id)")
            return id
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let listing = json["listing"] as? [String: Any], let id = listing["id"] as? String {
            print("✅ ListingsService: Объявление создано (nested id): \(id)")
            return id
        }

        let message = String(data: data, encoding: .utf8) ?? "Не удалось получить id объявления из ответа"
        throw NetworkError.decodingFailed(NSError(domain: "ListingsService", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
    }

    func uploadFile(_ imageData: Data, fileName: String, mimeType: String = "image/jpeg") async throws -> String {
        print("🔍 ListingsService: Загружаем файл /files/upload")
        let response: FileUploadResponse = try await NetworkClient.shared.uploadMultipart(path: "/files/upload", fileName: fileName, fileData: imageData, mimeType: mimeType)
        print("✅ ListingsService: Файл загружен: \(response.url)")
        return response.url
    }

    func uploadFileUrl(
        _ imageData: Data,
        fileName: String,
        mimeType: String = "image/jpeg"
    ) async throws -> String {

        print("🔍 ListingsService: Загружаем файл /files/upload")

        let boundary = "Boundary-\(UUID().uuidString)"

        let body = try NetworkClient.shared.makeMultipartFormDataBody(
            fieldName: "file",
            fileName: fileName,
            fileData: imageData,
            mimeType: mimeType,
            boundary: boundary
        )

        let (data, _) = try await NetworkClient.shared.requestWithResponse(
            path: "/files/upload",
            method: .post,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )

        if let response = try? JSONDecoder().decode(FileUploadResponse.self, from: data) {
            print("✅ ListingsService: Файл загружен: \(response.url)")
            return response.url
        }

        throw NetworkError.decodingFailed(
            NSError(
                domain: "ListingsService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось получить URL файла"]
            )
        )
    }

    func addListingPhoto(listingId: String, photoUrl: String, displayOrder: Int) async throws {
        let body = try JSONEncoder().encode(AddPhotoRequest(url: photoUrl, displayOrder: displayOrder))
        print("🔍 ListingsService: Добавляем фото к объявлению /listings/\(listingId)/photos")
        try await NetworkClient.shared.requestVoid(path: "/listings/\(listingId)/photos", method: .post, body: body)
        print("✅ ListingsService: Фото добавлено")
    }

    func updateListingStatus(listingId: String, status: String) async throws {
        let body = try JSONEncoder().encode(ChangeStatusRequest(status: status))
        print("🔍 ListingsService: Обновляем статус объявления /listings/\(listingId)/status")
        try await NetworkClient.shared.requestVoid(path: "/listings/\(listingId)/status", method: .patch, body: body)
        print("✅ ListingsService: Статус обновлён")
    }

    func fetchListingDetail(listingId: String) async throws -> ListingDetail {
        print("🔍 ListingsService: Загружаем детали объявления /listings/\(listingId)")
        let apiItem: ListingDetailAPIModel = try await NetworkClient.shared.request(path: "/listings/\(listingId)")
        print("✅ ListingsService: Детали объявления загружены")
        return ListingDetail(apiDetail: apiItem)
    }
}

struct CreateListingRequest: Encodable {
    let title: String
    let description: String
    let categoryId: String
    let weightGrams: Int
    let condition: String
    let transferType: String
    let transferMethod: String
    let city: String
    let district: String?
    let latitude: Double?
    let longitude: Double?
    let tags: [String]?
}
