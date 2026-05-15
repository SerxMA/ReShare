import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    func fetchMyProfile() async throws -> UserProfile {
        print("🔍 ProfileService: Начинаем запрос профиля /users/me")
        let profile: UserProfile = try await NetworkClient.shared.request(path: "/users/me")
        print("✅ ProfileService: Запрос профиля завершен успешно")
        return profile
    }

    func updateProfile(request: UpdateProfileRequest) async throws {
        print("🔍 ProfileService: Отправляем обновление профиля /users/me")
        let body = try JSONEncoder().encode(request)
        let _: UserProfile = try await NetworkClient.shared.request(path: "/users/me", method: .put, body: body)
        print("✅ ProfileService: Профиль обновлен успешно")
    }
}

struct UpdateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let bio: String
}
