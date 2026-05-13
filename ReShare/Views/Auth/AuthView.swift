import SwiftUI

struct AuthView: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    modeSwitcher

                    authForm

                    footer
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
            .onChange(of: viewModel.isAuthenticated) { isAuthenticated = $0 }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ShareSphere")
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
        )
    }

    private var modeSwitcher: some View {
        Picker(selection: $viewModel.mode, label: Text("Режим")) {
            Text("Войти").tag(AuthViewModel.Mode.login)
            Text("Регистрация").tag(AuthViewModel.Mode.register)
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 4)
    }

    private var authForm: some View {
        VStack(spacing: 16) {
            if viewModel.mode == .login {
                if viewModel.useEmailLogin {
                    InputBase(
                        text: $viewModel.authData.email,
                        placeholder: "Email",
                        textLabel: "Email",
                        helper: viewModel.errors["email"],
                        inputStyle: .shaded,
                        stateStyle: viewModel.errors["email"] != nil ? .error : .normal,
                        keyboardType: .emailAddress
                    )
                } else {
                    InputBase(
                        text: $viewModel.authData.phone,
                        placeholder: "+7 000 000 00 00",
                        textLabel: "Номер телефона",
                        helper: viewModel.errors["phone"],
                        inputStyle: .shaded,
                        stateStyle: viewModel.errors["phone"] != nil ? .error : .normal,
                        keyboardType: .phonePad
                    )
                }

                InputBase(
                    text: $viewModel.authData.password,
                    placeholder: "Пароль",
                    textLabel: "Пароль",
                    helper: viewModel.errors["password"],
                    inputStyle: .outline,
                    stateStyle: viewModel.errors["password"] != nil ? .error : .normal
                )

                if let serverMessage = viewModel.serverMessage {
                    Text(serverMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }

                ButtonBase(
                    action: viewModel.submit,
                    size: .large, color: .brand,
                    disabled: viewModel.isLoading
                ) {
                    Text(viewModel.primaryButtonTitle)
                        .foregroundColor(.white)
                }

                TextDividerView("Или", position: .middle)

                VStack(spacing: 12) {
                    ButtonBase(
                        action: viewModel.useEmailLogin ? viewModel.switchToPhoneLogin : viewModel.loginWithEmail,
                        size: .large, color: .outline
                    ) {
                        Text(viewModel.secondaryButtonTitle)
                            .foregroundColor(.primary)
                    }
                    ButtonBase(
                        action: viewModel.loginWithGoogle,
                        size: .large, color: .outline
                    ) {
                        Label("Войти через Google", systemImage: "globe")
                    }
                    ButtonBase(
                        action: viewModel.loginWithApple,
                        size: .large, color: .outline
                    ) {
                        Label("Войти через Apple", systemImage: "applelogo")
                    }
                }
            } else {
                InputBase(
                    text: $viewModel.authData.firstName,
                    placeholder: "Имя",
                    textLabel: "Имя",
                    helper: viewModel.errors["firstName"],
                    inputStyle: .outline,
                    stateStyle: viewModel.errors["firstName"] != nil ? .error : .normal
                )

                InputBase(
                    text: $viewModel.authData.lastName,
                    placeholder: "Фамилия",
                    textLabel: "Фамилия",
                    helper: viewModel.errors["lastName"],
                    inputStyle: .outline,
                    stateStyle: viewModel.errors["lastName"] != nil ? .error : .normal
                )

                InputBase(
                    text: $viewModel.authData.email,
                    placeholder: "Email",
                    textLabel: "Email",
                    helper: viewModel.errors["email"],
                    inputStyle: .shaded,
                    stateStyle: viewModel.errors["email"] != nil ? .error : .normal,
                    keyboardType: .emailAddress
                )

                InputBase(
                    text: $viewModel.authData.phone,
                    placeholder: "+7 000 000 00 00",
                    textLabel: "Телефон",
                    helper: viewModel.errors["phone"],
                    inputStyle: .shaded,
                    stateStyle: viewModel.errors["phone"] != nil ? .error : .normal,
                    keyboardType: .phonePad
                )

                InputBase(
                    text: $viewModel.authData.password,
                    placeholder: "Пароль",
                    textLabel: "Пароль",
                    helper: viewModel.errors["password"],
                    inputStyle: .outline,
                    stateStyle: viewModel.errors["password"] != nil ? .error : .normal
                )

                if let serverMessage = viewModel.serverMessage {
                    Text(serverMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }

                ButtonBase(
                    action: viewModel.submit,
                    size: .large, color: .brand,
                    disabled: viewModel.isLoading
                ) {
                    Text(viewModel.primaryButtonTitle)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
    }

    private var footer: some View {
        Text("Продолжая, вы соглашаетесь с условиями сервиса и подтверждаете, что ознакомились с политикой конфиденциальности.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
    }
}

