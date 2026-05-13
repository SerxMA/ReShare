import Foundation
import Security

let TOKEN_KEY = "accessToken"

final class TokenStorage {
    static let shared = TokenStorage()
    static let tokenKey = TOKEN_KEY

    private let service = Bundle.main.bundleIdentifier ?? "ReShare"

    private init() {}

    @discardableResult
    func save(token: String) -> Bool {
        print("🔑 TokenStorage: Сохраняем токен: \(token)")
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.tokenKey,
        ]

        let updateFields: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemUpdate(query as CFDictionary, updateFields as CFDictionary)
        if status == errSecSuccess {
            print("✅ TokenStorage: Токен успешно обновлен")
            return true
        }

        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus == errSecSuccess {
                print("✅ TokenStorage: Токен успешно добавлен")
                return true
            } else {
                print("❌ TokenStorage: Ошибка добавления токена: \(addStatus)")
                return false
            }
        }

        print("❌ TokenStorage: Ошибка обновления токена: \(status)")
        return false
    }

    func readToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                print("❌ TokenStorage: Ошибка чтения токена: \(status)")
            }
            return nil
        }

        print("🔑 TokenStorage: Токен прочитан: \(token)")
        return token
    }

    func clearToken() {
        print("🔑 TokenStorage: Очищаем токен")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.tokenKey,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("✅ TokenStorage: Токен успешно очищен")
        } else if status == errSecItemNotFound {
            print("ℹ️ TokenStorage: Токен не найден для очистки")
        } else {
            print("❌ TokenStorage: Ошибка очистки токена: \(status)")
        }
    }
}
