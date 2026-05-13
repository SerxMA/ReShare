import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        print("🔍 ProfileViewModel: Инициализация, начинаем загрузку профиля")
        loadProfile()
    }

    func loadProfile() {
        print("🔍 ProfileViewModel: Начинаем загрузку профиля")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                profile = try await ProfileService.shared.fetchMyProfile()
                print("✅ ProfileViewModel: Профиль загружен успешно")
                if let token = TokenStorage.shared.readToken() {
                    print("🔑 ProfileViewModel: Сохраненный access токен: \(token)")
                } else {
                    print("❌ ProfileViewModel: Access токен не найден в хранилище")
                }
            } catch {
                print("❌ ProfileViewModel: Ошибка загрузки профиля: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
