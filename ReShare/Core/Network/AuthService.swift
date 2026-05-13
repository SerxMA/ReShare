import Foundation

struct LoginRequest: Encodable {
    let login: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let phone: String?
    let password: String
    let firstName: String
    let lastName: String
    let role: String = "Donor"
}

final class AuthService {
    enum AuthError: LocalizedError {
        case missingToken

        var errorDescription: String? {
            switch self {
            case .missingToken:
                return "Не удалось получить access token от сервера"
            }
        }
    }

    static let shared = AuthService()
    private init() {}

    func login(request: LoginRequest) async throws {
        let body = try JSONEncoder().encode(request)
        print("🔍 AuthService: Отправляем запрос на логин")
        let (data, response) = try await NetworkClient.shared.requestWithResponse(path: "/auth/login", method: .post, body: body)
        print("✅ AuthService: Логин успешен, статус: \(response.statusCode)")
        print("🔍 AuthService: Headers ответа: \(response.allHeaderFields)")
        if let responseBody = String(data: data, encoding: .utf8) {
            print("🔍 AuthService: Тело ответа: \(responseBody)")
        }
        try storeAccessToken(from: response, data: data)
    }

    func register(request: RegisterRequest) async throws {
        let body = try JSONEncoder().encode(request)
        print("🔍 AuthService: Отправляем запрос на регистрацию")
        let (data, response) = try await NetworkClient.shared.requestWithResponse(path: "/auth/register", method: .post, body: body)
        print("✅ AuthService: Регистрация успешна, статус: \(response.statusCode)")
        print("🔍 AuthService: Headers ответа: \(response.allHeaderFields)")
        if let responseBody = String(data: data, encoding: .utf8) {
            print("🔍 AuthService: Тело ответа: \(responseBody)")
        }
        try storeAccessToken(from: response, data: data)
    }

    func logout() async throws {
        print("🔍 AuthService: Отправляем запрос на выход")
        try await NetworkClient.shared.requestVoid(path: "/auth/logout", method: .post)
        print("✅ AuthService: Выход успешен, очищаем токен")
        TokenStorage.shared.clearToken()
        deleteAccessTokenCookie()
    }

    private func storeAccessToken(from response: HTTPURLResponse, data: Data) throws {
        if let token = tokenFromCookies(response: response) {
            print("🔑 AuthService: Токен найден в cookies: \(token)")
            TokenStorage.shared.save(token: token)
            return
        }

        if let token = tokenFromHeaders(response: response) {
            print("🔑 AuthService: Токен найден в headers: \(token)")
            TokenStorage.shared.save(token: token)
            return
        }

        if let token = tokenFromBody(data: data) {
            print("🔑 AuthService: Токен найден в теле ответа: \(token)")
            TokenStorage.shared.save(token: token)
            return
        }

        print("❌ AuthService: Токен не найден нигде, проверяем все cookies в хранилище")
        let allCookies = HTTPCookieStorage.shared.cookies ?? []
        print("ℹ️ AuthService: Все cookies: \(allCookies.map { "\($0.name)=\($0.value)" })")
        throw AuthError.missingToken
    }

    private func tokenFromCookies(response: HTTPURLResponse) -> String? {
        let possibleNames = ["accessToken", "token", "access_token", "authToken"]

        if let url = response.url {
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            print("🔍 AuthService: Cookies в хранилище для \(url): \(cookies.map { "\($0.name)=\($0.value.isEmpty ? "[empty]" : $0.value), httpOnly=\($0.isHTTPOnly), secure=\($0.isSecure)" })")
        }

        if let url = response.url,
           let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            for name in possibleNames {
                if let cookie = cookies.first(where: { $0.name == name }) {
                    print("🔑 AuthService: Cookie найден в хранилище: name=\(cookie.name), value=\(cookie.value), httpOnly=\(cookie.isHTTPOnly), secure=\(cookie.isSecure), domain=\(cookie.domain), path=\(cookie.path)")
                    if !cookie.value.isEmpty {
                        return cookie.value
                    }
                }
            }
        }

        let headerFields = response.allHeaderFields.reduce(into: [String: String]()) { result, header in
            if let key = header.key as? String, let value = header.value as? String {
                result[key] = value
                result[key.lowercased()] = value
            }
        }

        print("🔍 AuthService: Header fields: \(headerFields)")

        if let rawSetCookie = headerFields["Set-Cookie"] ?? headerFields["set-cookie"] {
            if let token = tokenFromSetCookieHeader(rawSetCookie) {
                print("🔑 AuthService: Токен найден в Set-Cookie: \(token)")
                return token
            }
        }

        if let url = response.url {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            print("🔍 AuthService: Cookies из headers: \(cookies.map { "\($0.name)=\($0.value.isEmpty ? "[empty]" : $0.value), httpOnly=\($0.isHTTPOnly), secure=\($0.isSecure)" })")
            for name in possibleNames {
                if let cookie = cookies.first(where: { $0.name == name }) {
                    print("🔑 AuthService: Cookie из headers найден: name=\(cookie.name), value=\(cookie.value), httpOnly=\(cookie.isHTTPOnly), secure=\(cookie.isSecure), domain=\(cookie.domain), path=\(cookie.path)")
                    if !cookie.value.isEmpty {
                        return cookie.value
                    }
                }
            }
        }

        print("❌ AuthService: Cookie с именами \(possibleNames) не найден")
        return nil
    }

    private func tokenFromSetCookieHeader(_ header: String) -> String? {
        let components = header.components(separatedBy: ", ")
        for rawCookie in components {
            guard rawCookie.contains("accessToken=") else { continue }
            let parts = rawCookie.components(separatedBy: ";")
            guard let tokenPart = parts.first(where: { $0.contains("accessToken=") }) else { continue }
            let tokenValue = tokenPart.replacingOccurrences(of: "accessToken=", with: "")
            let decoded = tokenValue.removingPercentEncoding ?? tokenValue
            if !decoded.isEmpty {
                return decoded
            }
        }
        return nil
    }

    private func tokenFromHeaders(response: HTTPURLResponse) -> String? {
        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, header in
            if let key = header.key as? String, let value = header.value as? String {
                result[key.lowercased()] = value
            }
        }

        print("ℹ️ AuthService: Headers ответа: \(headers)")

        if let authHeader = headers["authorization"] {
            if let token = authHeader.split(separator: " ").last.map(String.init) {
                print("🔑 AuthService: Токен найден в header Authorization: \(token)")
                return token
            }
        }

        if let authHeader = headers["authorisation"] {
            if let token = authHeader.split(separator: " ").last.map(String.init) {
                print("🔑 AuthService: Токен найден в header authorization: \(token)")
                return token
            }
        }

        print("❌ AuthService: Токен не найден в headers Authorization или authorization")
        return nil
    }

    private func tokenFromBody(data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = object as? [String: Any]
        else {
            print("❌ AuthService: Тело ответа не является JSON или пустое")
            if let string = String(data: data, encoding: .utf8) {
                print("ℹ️ AuthService: Тело ответа как строка: \(string)")
            }
            return nil
        }

        print("ℹ️ AuthService: JSON в теле ответа: \(json)")

        if let token = json["accessToken"] as? String {
            return token
        }

        if let token = json["token"] as? String {
            return token
        }

        if let token = json["access_token"] as? String {
            return token
        }

        print("❌ AuthService: Токен не найден в JSON под ключами accessToken, token, access_token")
        return nil
    }

    private func deleteAccessTokenCookie() {
        HTTPCookieStorage.shared.cookies?.filter { $0.name == TOKEN_KEY }.forEach { cookie in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
}
