import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode {
        case login
        case register
    }

    @Published var mode: Mode = .login
    @Published var authData = AuthFormData()
    @Published var useEmailLogin = false
    @Published var errors: [String: String] = [:]
    @Published var serverMessage: String?
    @Published var isLoading = false
    @Published var isAuthenticated = false

    var title: String {
        mode == .login ? "Добро пожаловать в ShareSphere!" : "Создайте аккаунт"
    }

    var subtitle: String {
        mode == .login
            ? "Станьте частью сообщества, где хорошие вещи находят новых владельцев, а полезные ресурсы не превращаются в отходы."
            : "Зарегистрируйтесь, чтобы легко отдавать, получать и обмениваться вещами в вашем городе."
    }

    var primaryButtonTitle: String {
        mode == .login ? "Войти" : "Зарегистрироваться"
    }

    var secondaryButtonTitle: String {
        if mode == .login {
            return useEmailLogin ? "Войти через телефон" : "Войти через почту"
        }
        return "Уже есть аккаунт? Войти"
    }

    func toggleMode() {
        mode = mode == .login ? .register : .login
        useEmailLogin = false
        errors = [:]
        serverMessage = nil
    }

    func switchToEmailLogin() {
        useEmailLogin = true
        errors = [:]
        serverMessage = nil
    }

    func switchToPhoneLogin() {
        useEmailLogin = false
        errors = [:]
        serverMessage = nil
    }

    func submit() {
        errors = [:]
        serverMessage = nil

        if mode == .login {
            validateLogin()
        } else {
            validateRegister()
        }

        guard errors.isEmpty else { return }

        isLoading = true
        Task {
            do {
                switch mode {
                case .login:
                    try await performLogin()
                case .register:
                    try await performRegistration()
                }
            } catch {
                serverMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func loginWithEmail() {
        switchToEmailLogin()
    }

    func loginWithGoogle() {
        serverMessage = "Вход через Google пока не поддерживается."
    }

    func loginWithApple() {
        serverMessage = "Вход через Apple пока не поддерживается."
    }

    private func performLogin() async throws {
        let loginValue = useEmailLogin ? authData.email.trimmingCharacters(in: .whitespacesAndNewlines) : authData.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordValue = authData.password.trimmingCharacters(in: .whitespacesAndNewlines)

        let request = LoginRequest(login: loginValue, password: passwordValue)
        try await AuthService.shared.login(request: request)
        isAuthenticated = TokenStorage.shared.readToken() != nil
    }

    private func performRegistration() async throws {
        let phoneValue = authData.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = RegisterRequest(
            email: authData.email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phoneValue.isEmpty ? nil : phoneValue,
            password: authData.password.trimmingCharacters(in: .whitespacesAndNewlines),
            firstName: authData.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: authData.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        try await AuthService.shared.register(request: request)
        isAuthenticated = TokenStorage.shared.readToken() != nil
    }

    private func validateLogin() {
        if useEmailLogin {
            if authData.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors["email"] = "Введите email"
            }
        } else {
            if authData.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors["phone"] = "Введите номер телефона"
            }
        }

        if authData.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["password"] = "Введите пароль"
        }
    }

    private func validateRegister() {
        if authData.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["firstName"] = "Введите имя"
        }
        if authData.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["lastName"] = "Введите фамилию"
        }
        if authData.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["email"] = "Введите email"
        }
        if authData.password.trimmingCharacters(in: .whitespacesAndNewlines).count < 8 {
            errors["password"] = "Пароль должен быть не менее 8 символов"
        }
    }
}
