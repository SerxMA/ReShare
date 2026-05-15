import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var isEditingProfile = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statusSection
                    metricsSection
                    actionsSection
                    Spacer(minLength: 24)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isEditingProfile) {
                if let profile = viewModel.profile {
                    EditProfileView(profile: profile)
                        .onDisappear {
                            viewModel.loadProfile()
                        }
                }
            }
            .onAppear {
                print("🔍 ProfileView: Вход в профиль, начинаем загрузку")
                viewModel.loadProfile()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                profileAvatar

                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.profile?.fullName ?? "Пользователь")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let city = viewModel.profile?.city, !city.isEmpty {
                        Text(city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(viewModel.profile?.bio ?? "О себе пока ничего не указано.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(20)

            HStack(spacing: 12) {
                Button(action: { isEditingProfile = true }) {
                    Label("Редактировать профиль", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(14)
                }

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 48, height: 48)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                }
            }
        }
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 88, height: 88)

            Image(systemName: "person.crop.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundColor(.blue)
        }
    }

    private var statusSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                starRating
                Spacer()
                Text(statusSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
    }

    private var starRating: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", viewModel.profile?.rating ?? 0.0))
                .font(.headline)
                .foregroundColor(.primary)
        }
    }

    private var statusSubtitle: String {
        let reviews = viewModel.profile?.reviewCount ?? 0
        let year = viewModel.profile?.joinedYear ?? "—"
        return "\(reviews) отзыва • на платформе с \(year)"
    }

    private var metricsSection: some View {
        let metrics = metricItems

        return VStack(alignment: .leading, spacing: 12) {
            Text("Экологические показатели")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(metrics) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(item.value)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(item.subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(item.color.opacity(0.18))
                    .cornerRadius(18)
                }
            }
        }
        .padding(.top, 4)
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: logoutTapped) {
                HStack {
                    Image(systemName: "power")
                    Text("Выйти")
                    Spacer()
                }
                .padding()
                .background(Color(.systemRed).opacity(0.14))
                .foregroundColor(.red)
                .cornerRadius(16)
            }
        }
    }

    private func logoutTapped() {
        print("🔍 ProfileView: Нажата кнопка выхода")
        Task {
            if TokenStorage.shared.readToken() != nil {
                do {
                    try await AuthService.shared.logout()
                } catch {
                    print("❌ ProfileView: Ошибка при выходе: \(error.localizedDescription)")
                    // Игнорируем ошибку выхода, но очищаем локальный токен
                }
            } else {
                print("ℹ️ ProfileView: Токен не найден, пропускаем запрос на сервер")
            }

            TokenStorage.shared.clearToken()
            isAuthenticated = false
            print("✅ ProfileView: Выход завершен")
        }
    }

    private var metricItems: [ProfileMetric] {
        let stats = viewModel.profile?.ecoStats

        return [
            ProfileMetric(
                title: "Отдано",
                value: stats.map { "\($0.itemsGifted)" } ?? "—",
                subtitle: "товаров подарено",
                color: .green
            ),
            ProfileMetric(
                title: "Получено",
                value: stats.map { "\($0.itemsReceived)" } ?? "—",
                subtitle: "товаров получено",
                color: .blue
            ),
            ProfileMetric(
                title: "CO₂",
                value: stats.map { String(format: "%.1f кг", $0.co2SavedKg) } ?? "—",
                subtitle: "сохранено CO₂",
                color: .orange
            ),
            ProfileMetric(
                title: "Отходы",
                value: stats.map { String(format: "%.1f кг", $0.wasteSavedKg) } ?? "—",
                subtitle: "сохранено отходов",
                color: .purple
            ),
        ]
    }
}

private struct ProfileMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let color: Color
}
