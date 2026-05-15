import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum NetworkError: LocalizedError {
    case invalidURL
    case badResponse(statusCode: Int, message: String?)
    case emptyData
    case decodingFailed(Error)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL для запроса"
        case let .badResponse(statusCode, message):
            if let message = message, !message.isEmpty {
                return message
            }
            return "Ошибка сервера: код \(statusCode)"
        case .emptyData:
            return "Сервер вернул пустой ответ"
        case let .decodingFailed(error):
            return "Не удалось разобрать данные: \(error.localizedDescription)"
        case let .underlying(error):
            return error.localizedDescription
        }
    }
}

struct EmptyResponse: Decodable {}

final class NetworkClient {
    static let shared = NetworkClient()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        contentType: String = "application/json",
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let request = try makeRequest(path: path, method: method, body: body, contentType: contentType, queryItems: queryItems)

        if path.contains("/users/me") {
            print("🔍 NetworkClient: Отправляем запрос на \(path)")
            if let authHeader = request.value(forHTTPHeaderField: "authorization") {
                print("🔑 NetworkClient: Заголовок authorization: \(authHeader)")
            } else {
                print("❌ NetworkClient: Заголовок authorization отсутствует")
            }
        }

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if path.contains("/users/me") {
                print("❌ NetworkClient: Ошибка сети при запросе \(path): \(error.localizedDescription)")
            }
            throw NetworkError.underlying(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            if path.contains("/users/me") {
                print("❌ NetworkClient: Неверный URL для \(path)")
            }
            throw NetworkError.invalidURL
        }

        if path.contains("/users/me") {
            print("🔍 NetworkClient: Получен ответ для \(path) со статусом \(httpResponse.statusCode)")
        }

        guard 200 ... 299 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8)
            if path.contains("/users/me") {
                print("❌ NetworkClient: Ошибка сервера для \(path): статус \(httpResponse.statusCode), сообщение: \(message ?? "нет")")
            }
            throw NetworkError.badResponse(statusCode: httpResponse.statusCode, message: message)
        }

        guard !data.isEmpty else {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            throw NetworkError.emptyData
        }

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            if path.contains("/users/me") {
                print("✅ NetworkClient: Данные для \(path) успешно декодированы")
            }
            return decoded
        } catch {
            if path.contains("/users/me") {
                print("❌ NetworkClient: Ошибка декодирования для \(path): \(error.localizedDescription)")
            }
            throw NetworkError.decodingFailed(error)
        }
    }

    func requestVoid(
        path: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        contentType: String = "application/json",
        queryItems: [URLQueryItem] = []
    ) async throws {
        let request = try makeRequest(path: path, method: method, body: body, contentType: contentType, queryItems: queryItems)
        let (_, response): (Data, URLResponse)

        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.underlying(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidURL
        }

        guard 200 ... 299 ~= httpResponse.statusCode else {
            throw NetworkError.badResponse(statusCode: httpResponse.statusCode, message: nil)
        }
    }

    private func makeRequest(
        path: String,
        method: HTTPMethod,
        body: Data?,
        contentType: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        let normalizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent(normalizedPath), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = authToken(for: url) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        request.httpShouldHandleCookies = true
        request.allowsConstrainedNetworkAccess = true
        request.allowsExpensiveNetworkAccess = true

        return request
    }

    private func authToken(for url: URL) -> String? {
        if let token = TokenStorage.shared.readToken() {
            if url.absoluteString.contains("/users/me") {
                print("🔑 NetworkClient: Токен найден в Keychain для \(url.lastPathComponent)")
            }
            return token
        }

        let cookieToken = HTTPCookieStorage.shared.cookies(for: url)?
            .first(where: { $0.name == TOKEN_KEY })?.value

        if let cookieToken {
            if url.absoluteString.contains("/users/me") {
                print("🔑 NetworkClient: Токен найден в cookie для \(url.lastPathComponent), сохраняем в Keychain: \(cookieToken)")
            }
            TokenStorage.shared.save(token: cookieToken)
            return cookieToken
        }

        if url.absoluteString.contains("/users/me") {
            print("❌ NetworkClient: Токен не найден ни в Keychain, ни в cookie для \(url.lastPathComponent)")
        }
        return nil
    }

    func requestWithResponse(
        path: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        contentType: String = "application/json",
        queryItems: [URLQueryItem] = []
    ) async throws -> (Data, HTTPURLResponse) {
        let request = try makeRequest(path: path, method: method, body: body, contentType: contentType, queryItems: queryItems)

        if path.contains("/auth/login") || path.contains("/auth/register") {
            print("🔍 NetworkClient: Отправляем запрос \(method.rawValue) \(path)")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if path.contains("/auth/login") || path.contains("/auth/register") {
                print("❌ NetworkClient: Ошибка сети при запросе \(path): \(error.localizedDescription)")
            }
            throw NetworkError.underlying(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            if path.contains("/auth/login") || path.contains("/auth/register") {
                print("❌ NetworkClient: Неверный URL для \(path)")
            }
            throw NetworkError.invalidURL
        }

        if path.contains("/auth/login") || path.contains("/auth/register") {
            print("🔍 NetworkClient: Получен ответ для \(path) со статусом \(httpResponse.statusCode)")
        }

        guard 200 ... 299 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8)
            if path.contains("/auth/login") || path.contains("/auth/register") {
                print("❌ NetworkClient: Ошибка сервера для \(path): статус \(httpResponse.statusCode), сообщение: \(message ?? "нет")")
            }
            throw NetworkError.badResponse(statusCode: httpResponse.statusCode, message: message)
        }

        return (data, httpResponse)
    }

    func uploadMultipart<T: Decodable>(
        path: String,
        fileName: String,
        fileData: Data,
        mimeType: String = "image/jpeg",
        fieldName: String = "file"
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = try makeMultipartFormDataBody(fieldName: fieldName, fileName: fileName, fileData: fileData, mimeType: mimeType, boundary: boundary)
        return try await request(path: path, method: .post, body: body, contentType: "multipart/form-data; boundary=\(boundary)")
    }

    func makeMultipartFormDataBody(
        fieldName: String,
        fileName: String,
        fileData: Data,
        mimeType: String,
        boundary: String
    ) throws -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        body.append(fileData)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")

        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
