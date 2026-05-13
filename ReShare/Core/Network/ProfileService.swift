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
}
